module "tags" {
  source = "../../modules/terraform-azurerm-compeer-platform-tags"

  environment         = var.environment
  application         = var.platform_tags.application
  business_owner      = var.platform_tags.business_owner
  source_repo         = var.platform_tags.source_repo
  terraform_workspace = var.platform_tags.terraform_workspace
  recovery_tier       = var.platform_tags.recovery_tier
  cost_center         = var.platform_tags.cost_center
  data_classification = var.platform_tags.data_classification
  compliance_boundary = var.platform_tags.compliance_boundary
  additional_tags     = var.platform_tags.additional_tags
}

module "resource_group" {
  source = "../../modules/terraform-azurerm-compeer-resource-group"

  name     = var.resource_group.name
  location = var.location
  tags     = module.tags.tags
}

locals {
  default_windows_image = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  data_disks = merge([
    for controller_key, controller in var.domain_controllers : {
      for disk_key, disk in try(controller.data_disks, {}) : "${controller_key}:${disk_key}" => merge(disk, {
        controller_key = controller_key
        disk_key       = disk_key
        zone           = coalesce(try(disk.zone, null), try(controller.zone, null))
      })
    }
  ]...)

  domain_joins = {
    for controller_key, controller in var.domain_controllers : controller_key => controller.domain_join
    if coalesce(try(controller.domain_join.enabled, null), false)
  }

  scope_ids = merge(
    {
      resource_group = module.resource_group.id
    },
    {
      for key, value in module.network_interfaces : "nic:${key}" => value.id
    },
    {
      for key, value in module.domain_controllers : "vm:${key}" => value.id
    },
    {
      for key, value in azurerm_managed_disk.data : "disk:${key}" => value.id
    },
    var.additional_scopes
  )

  role_assignment_inputs = {
    for key, assignment in var.role_assignments : key => merge(assignment, {
      scope = coalesce(
        try(assignment.scope, null),
        try(local.scope_ids[assignment.scope_key], null)
      )
    })
  }
}

resource "terraform_data" "controller_contract" {
  input = {
    domain_controller_keys = sort(keys(var.domain_controllers))
    domain_join_keys       = sort(keys(local.domain_joins))
  }

  lifecycle {
    precondition {
      condition = alltrue([
        for key in keys(var.domain_controllers) : contains(keys(var.admin_passwords), key)
      ])
      error_message = "admin_passwords must contain a sensitive password entry for each domain controller key."
    }

    precondition {
      condition = alltrue([
        for key, join in local.domain_joins : contains(keys(var.domain_join_passwords), coalesce(try(join.domain_password_key, null), key))
      ])
      error_message = "domain_join_passwords must contain a sensitive password entry for each enabled domain join."
    }
  }
}

module "network_interfaces" {
  source   = "../../modules/terraform-azurerm-compeer-network-interface"
  for_each = var.domain_controllers

  name                           = each.value.nic_name
  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  dns_servers                    = try(each.value.dns_servers, null)
  accelerated_networking_enabled = try(each.value.accelerated_networking_enabled, true)
  ip_forwarding_enabled          = try(each.value.ip_forwarding_enabled, false)
  ip_configurations = {
    (try(each.value.ip_configuration_name, "primary")) = {
      subnet_id                     = each.value.subnet_id
      private_ip_address_allocation = try(each.value.private_ip_address_allocation, "Static")
      private_ip_address            = each.value.private_ip_address
      primary                       = true
    }
  }
  tags = module.tags.tags
}

module "domain_controllers" {
  source   = "../../modules/terraform-azurerm-compeer-windows-vm"
  for_each = var.domain_controllers

  name                       = each.value.name
  resource_group_name        = module.resource_group.name
  location                   = module.resource_group.location
  vm_size                    = try(each.value.vm_size, "Standard_D2s_v5")
  network_interface_ids      = [module.network_interfaces[each.key].id]
  admin_username             = try(each.value.admin_username, "azureadmin")
  admin_password             = var.admin_passwords[each.key]
  computer_name              = try(each.value.computer_name, null)
  availability_set_id        = try(each.value.availability_set_id, null)
  zone                       = try(each.value.zone, null)
  source_image_id            = try(each.value.source_image_id, null)
  source_image_reference     = try(each.value.source_image_id, null) == null ? coalesce(try(each.value.source_image_reference, null), local.default_windows_image) : null
  plan                       = try(each.value.plan, null)
  license_type               = try(each.value.license_type, "Windows_Server")
  timezone                   = try(each.value.timezone, "UTC")
  provision_vm_agent         = try(each.value.provision_vm_agent, true)
  allow_extension_operations = try(each.value.allow_extension_operations, true)
  enable_automatic_updates   = try(each.value.enable_automatic_updates, true)
  patch_mode                 = try(each.value.patch_mode, "AutomaticByPlatform")
  patch_assessment_mode      = try(each.value.patch_assessment_mode, "AutomaticByPlatform")
  hotpatching_enabled        = try(each.value.hotpatching_enabled, false)
  secure_boot_enabled        = try(each.value.secure_boot_enabled, true)
  vtpm_enabled               = try(each.value.vtpm_enabled, true)
  encryption_at_host_enabled = try(each.value.encryption_at_host_enabled, true)
  identity                   = try(each.value.identity, null)
  boot_diagnostics           = try(each.value.boot_diagnostics, null)
  additional_capabilities    = try(each.value.additional_capabilities, null)
  os_disk = coalesce(try(each.value.os_disk, null), {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  })
  tags = module.tags.tags

  depends_on = [terraform_data.controller_contract]
}

resource "azurerm_managed_disk" "data" {
  for_each = local.data_disks

  name                 = each.value.name
  resource_group_name  = module.resource_group.name
  location             = module.resource_group.location
  storage_account_type = try(each.value.storage_account_type, "Premium_LRS")
  create_option        = try(each.value.create_option, "Empty")
  disk_size_gb         = each.value.disk_size_gb
  zone                 = try(each.value.zone, null)
  tags                 = module.tags.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  for_each = local.data_disks

  managed_disk_id    = azurerm_managed_disk.data[each.key].id
  virtual_machine_id = module.domain_controllers[each.value.controller_key].id
  lun                = each.value.lun
  caching            = try(each.value.caching, "ReadOnly")
}

module "vm_diagnostics" {
  source = "../../modules/terraform-azurerm-compeer-diagnostic-settings"
  for_each = {
    for key, controller in var.domain_controllers : key => controller.diagnostics
    if coalesce(try(controller.diagnostics.enabled, null), false)
  }

  name                           = coalesce(try(each.value.name, null), "${module.domain_controllers[each.key].name}-diag")
  target_resource_id             = module.domain_controllers[each.key].id
  log_analytics_workspace_id     = try(each.value.log_analytics_workspace_id, null)
  log_analytics_destination_type = try(each.value.log_analytics_destination_type, null)
  storage_account_id             = try(each.value.storage_account_id, null)
  eventhub_authorization_rule_id = try(each.value.eventhub_authorization_rule_id, null)
  eventhub_name                  = try(each.value.eventhub_name, null)
  partner_solution_id            = try(each.value.partner_solution_id, null)
  logs                           = try(each.value.logs, {})
  metrics                        = try(each.value.metrics, {})
}

module "domain_join" {
  source   = "../../modules/terraform-azurerm-compeer-windows-vm-domain-join"
  for_each = local.domain_joins

  name                 = try(each.value.name, "domain-join")
  virtual_machine_id   = module.domain_controllers[each.key].id
  domain_name          = each.value.domain_name
  ou_path              = try(each.value.ou_path, null)
  domain_username      = each.value.domain_username
  domain_password      = var.domain_join_passwords[coalesce(try(each.value.domain_password_key, null), each.key)]
  restart              = try(each.value.restart, true)
  join_options         = try(each.value.join_options, 3)
  type_handler_version = try(each.value.type_handler_version, "1.3")

  depends_on = [terraform_data.controller_contract]
}

module "role_assignments" {
  source = "../../modules/terraform-azurerm-compeer-role-assignments"

  assignments = local.role_assignment_inputs
}

resource "azurerm_management_lock" "this" {
  for_each = var.management_locks

  name       = each.value.name
  scope      = coalesce(try(each.value.scope, null), try(local.scope_ids[each.value.scope_key], null))
  lock_level = each.value.lock_level
  notes      = try(each.value.notes, null)
}

module "operational_contracts" {
  source = "../../modules/terraform-azurerm-compeer-operational-contracts"

  contracts = var.operational_contracts
}
