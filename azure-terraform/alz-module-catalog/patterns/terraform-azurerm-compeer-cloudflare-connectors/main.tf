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
  default_linux_image = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  extensions = merge([
    for connector_key, connector in var.connectors : {
      for extension_key, extension in try(connector.extensions, {}) : "${connector_key}:${extension_key}" => merge(extension, {
        connector_key = connector_key
        extension_key = extension_key
      })
    }
  ]...)

  scope_ids = merge(
    {
      resource_group = module.resource_group.id
    },
    {
      for key, value in module.network_interfaces : "nic:${key}" => value.id
    },
    {
      for key, value in azurerm_linux_virtual_machine.this : "vm:${key}" => value.id
    },
    var.additional_scopes
  )

  role_assignment_inputs = {
    for key, assignment in var.role_assignments : key => merge(assignment, {
      scope = coalesce(try(assignment.scope, null), try(local.scope_ids[assignment.scope_key], null))
    })
  }
}

resource "terraform_data" "connector_contract" {
  input = {
    connector_keys = sort(keys(var.connectors))
    extension_keys = sort(keys(local.extensions))
  }

  lifecycle {
    precondition {
      condition = alltrue([
        for key, connector in var.connectors :
        !coalesce(try(connector.disable_password_authentication, null), true) || length(try(connector.admin_ssh_keys, [])) > 0
      ])
      error_message = "Each connector using SSH authentication must include at least one admin_ssh_keys entry."
    }

    precondition {
      condition = alltrue([
        for key, connector in var.connectors :
        coalesce(try(connector.disable_password_authentication, null), true) || contains(keys(var.admin_passwords), key)
      ])
      error_message = "admin_passwords must contain a sensitive password entry for each connector with password authentication enabled."
    }
  }
}

module "network_interfaces" {
  source   = "../../modules/terraform-azurerm-compeer-network-interface"
  for_each = var.connectors

  name                           = each.value.nic_name
  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  dns_servers                    = try(each.value.dns_servers, null)
  accelerated_networking_enabled = try(each.value.accelerated_networking_enabled, true)
  ip_forwarding_enabled          = try(each.value.ip_forwarding_enabled, false)
  ip_configurations = {
    (try(each.value.ip_configuration_name, "primary")) = {
      subnet_id                     = each.value.subnet_id
      private_ip_address_allocation = try(each.value.private_ip_address_allocation, "Dynamic")
      private_ip_address            = try(each.value.private_ip_address, null)
      primary                       = true
    }
  }
  tags = module.tags.tags
}

resource "azurerm_linux_virtual_machine" "this" {
  for_each = var.connectors

  name                            = each.value.name
  computer_name                   = try(each.value.computer_name, null)
  resource_group_name             = module.resource_group.name
  location                        = module.resource_group.location
  size                            = try(each.value.vm_size, "Standard_D2s_v5")
  zone                            = try(each.value.zone, null)
  admin_username                  = try(each.value.admin_username, "azureadmin")
  admin_password                  = try(each.value.disable_password_authentication, true) ? null : var.admin_passwords[each.key]
  disable_password_authentication = try(each.value.disable_password_authentication, true)
  network_interface_ids           = [module.network_interfaces[each.key].id]
  custom_data                     = try(var.custom_data_by_key[each.key], null)
  provision_vm_agent              = try(each.value.provision_vm_agent, true)
  allow_extension_operations      = try(each.value.allow_extension_operations, true)
  encryption_at_host_enabled      = try(each.value.encryption_at_host_enabled, true)
  secure_boot_enabled             = try(each.value.secure_boot_enabled, true)
  vtpm_enabled                    = try(each.value.vtpm_enabled, true)
  patch_mode                      = try(each.value.patch_mode, "ImageDefault")
  patch_assessment_mode           = try(each.value.patch_assessment_mode, "ImageDefault")
  source_image_id                 = try(each.value.source_image_id, null)
  tags                            = module.tags.tags

  os_disk {
    name                      = try(each.value.os_disk.name, null)
    caching                   = try(each.value.os_disk.caching, "ReadWrite")
    storage_account_type      = try(each.value.os_disk.storage_account_type, "Premium_LRS")
    disk_size_gb              = try(each.value.os_disk.disk_size_gb, null)
    write_accelerator_enabled = try(each.value.os_disk.write_accelerator_enabled, null)
    disk_encryption_set_id    = try(each.value.os_disk.disk_encryption_set_id, null)
  }

  dynamic "admin_ssh_key" {
    for_each = try(each.value.disable_password_authentication, true) ? try(each.value.admin_ssh_keys, []) : []
    content {
      username   = admin_ssh_key.value.username
      public_key = admin_ssh_key.value.public_key
    }
  }

  dynamic "identity" {
    for_each = try(each.value.identity, null) == null ? [] : [each.value.identity]
    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  dynamic "boot_diagnostics" {
    for_each = try(each.value.boot_diagnostics, null) == null ? [] : [each.value.boot_diagnostics]
    content {
      storage_account_uri = try(boot_diagnostics.value.storage_account_uri, null)
    }
  }

  dynamic "plan" {
    for_each = try(each.value.plan, null) == null ? [] : [each.value.plan]
    content {
      name      = plan.value.name
      publisher = plan.value.publisher
      product   = plan.value.product
    }
  }

  dynamic "source_image_reference" {
    for_each = try(each.value.source_image_id, null) == null ? [coalesce(try(each.value.source_image_reference, null), local.default_linux_image)] : []
    content {
      publisher = source_image_reference.value.publisher
      offer     = source_image_reference.value.offer
      sku       = source_image_reference.value.sku
      version   = source_image_reference.value.version
    }
  }

  depends_on = [terraform_data.connector_contract]
}

resource "azurerm_virtual_machine_extension" "this" {
  for_each = local.extensions

  name                       = coalesce(try(each.value.name, null), each.value.extension_key)
  virtual_machine_id         = azurerm_linux_virtual_machine.this[each.value.connector_key].id
  publisher                  = each.value.publisher
  type                       = each.value.type
  type_handler_version       = each.value.type_handler_version
  auto_upgrade_minor_version = try(each.value.auto_upgrade_minor_version, true)
  automatic_upgrade_enabled  = try(each.value.automatic_upgrade_enabled, null)
  settings                   = jsonencode(try(each.value.settings, {}))
  protected_settings         = try(var.extension_protected_settings[coalesce(try(each.value.protected_settings_key, null), each.key)], null)
  tags                       = merge(module.tags.tags, try(each.value.tags, {}))
}

module "vm_diagnostics" {
  source = "../../modules/terraform-azurerm-compeer-diagnostic-settings"
  for_each = {
    for key, connector in var.connectors : key => connector.diagnostics
    if coalesce(try(connector.diagnostics.enabled, null), false)
  }

  name                           = coalesce(try(each.value.name, null), "${azurerm_linux_virtual_machine.this[each.key].name}-diag")
  target_resource_id             = azurerm_linux_virtual_machine.this[each.key].id
  log_analytics_workspace_id     = try(each.value.log_analytics_workspace_id, null)
  log_analytics_destination_type = try(each.value.log_analytics_destination_type, null)
  storage_account_id             = try(each.value.storage_account_id, null)
  eventhub_authorization_rule_id = try(each.value.eventhub_authorization_rule_id, null)
  eventhub_name                  = try(each.value.eventhub_name, null)
  partner_solution_id            = try(each.value.partner_solution_id, null)
  logs                           = try(each.value.logs, {})
  metrics                        = try(each.value.metrics, {})
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
