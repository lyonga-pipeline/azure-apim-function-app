# =============================================================================
# AD DS role install + domain promotion: NOT Terraform-owned (resolved)
#
# deploy-runbook.tf §7.2 / §15 always said AD DS role install and domain
# promotion should not be Terraform-owned (Ansible / PowerShell DSC instead),
# and that domain-admin secrets should never flow through Terraform
# variables. This pattern briefly carried a Terraform-owned bridge for both
# (azurerm_virtual_machine_extension.ad_ds_role_install /
# .ad_ds_promotion + var.ad_ds_promotion_passwords) to stand DCs up
# end-to-end during early build-out.
#
# Confirmed with the network/AD team: Terraform stops at a domain-joined,
# ready-to-promote VM. AD DS role installation and domain-controller
# promotion happen manually (or via the approved Ansible/DSC pipeline) once
# the VM has joined the domain. The Terraform-owned bridge has been removed
# accordingly - VM / NIC / disk / diagnostics / lock / domain-join resources
# below remain Terraform-owned.
# =============================================================================

module "tags" {
  source = "../../modules/terraform-azurerm-compeer-platform-tags"

  environment           = var.environment
  application           = var.platform_tags.application
  appcode               = var.platform_tags.appcode
  owner                 = var.platform_tags.owner
  source_repo           = var.platform_tags.source_repo
  created_on            = var.platform_tags.created_on
  criticality_tier      = var.platform_tags.criticality_tier
  data_classification   = var.platform_tags.data_classification
  lifecycle_state       = var.platform_tags.lifecycle_state
  cost_center           = var.platform_tags.cost_center
  gl_category           = var.platform_tags.gl_category
  application_component = var.platform_tags.application_component
  modified_on           = var.platform_tags.modified_on
  created_by            = var.platform_tags.created_by
  dr_tier               = var.platform_tags.dr_tier
  expiration_date       = var.platform_tags.expiration_date
  time_bound_exception  = var.platform_tags.time_bound_exception
  additional_tags       = var.platform_tags.additional_tags
}

module "resource_group" {
  source = "../../modules/terraform-azurerm-compeer-resource-group"

  name     = var.resource_group.name
  location = var.location
  tags     = module.tags.tags
}

# Dedicated identity VNet (23 Sep 2026 placement decision) - domain
# controllers and DNS live here, peered to the hub, isolating the Tier 0
# identity plane from the connectivity subscription. count-gated so a caller
# still on the legacy hub-hosted shape (identity_vnet = null) is unaffected.
module "identity_vnet" {
  source = "../../modules/terraform-azurerm-compeer-virtual-network"
  count  = var.identity_vnet == null ? 0 : 1

  name                = var.identity_vnet.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = var.identity_vnet.address_space
  dns_servers         = try(var.identity_vnet.dns_servers, null)
  subnets             = try(var.identity_vnet.subnets, {})
}

module "identity_vnet_to_hub_peering" {
  source = "../../modules/terraform-azurerm-compeer-vnet-peering"
  count  = var.identity_vnet != null && var.hub_connection != null ? 1 : 0

  peering_name                 = "peer-${var.identity_vnet.name}-to-hub"
  rg_name                      = module.resource_group.name
  vnet_name                    = module.identity_vnet[0].name
  remote_virtual_network_id    = var.hub_connection.hub_virtual_network_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = var.hub_connection.allow_forwarded_traffic
  allow_gateway_transit        = var.hub_connection.allow_gateway_transit
  use_remote_gateways          = var.hub_connection.use_remote_gateways
}

module "network_security_groups" {
  source   = "../../modules/terraform-azurerm-compeer-network-security-group"
  for_each = var.network_security_groups

  name                = each.value.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  security_rules = {
    for name, rule in try(each.value.rules, {}) : name => {
      name                                       = name
      description                                = try(rule.description, null)
      protocol                                   = rule.protocol
      source_port_range                          = try(rule.source_port_range, null)
      source_port_ranges                         = try(rule.source_port_ranges, null)
      destination_port_range                     = try(rule.destination_port_range, null)
      destination_port_ranges                    = try(rule.destination_port_ranges, null)
      source_address_prefix                      = try(rule.source_address_prefix, null)
      source_address_prefixes                    = try(rule.source_address_prefixes, null)
      source_application_security_group_ids      = try(rule.source_application_security_group_ids, null)
      destination_address_prefix                 = try(rule.destination_address_prefix, null)
      destination_address_prefixes               = try(rule.destination_address_prefixes, null)
      destination_application_security_group_ids = try(rule.destination_application_security_group_ids, null)
      access                                     = rule.access
      priority                                   = rule.priority
      direction                                  = rule.direction
    }
  }
  tags = module.tags.tags
}

module "route_tables" {
  source   = "../../modules/terraform-azurerm-compeer-route-table"
  for_each = var.route_tables

  name                          = each.value.name
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  bgp_route_propagation_enabled = try(each.value.bgp_route_propagation_enabled, null)
  routes                        = try(each.value.routes, {})
  tags                          = module.tags.tags
}

locals {
  # Associations declared inline on identity_vnet.subnets[*].{nsg_key,
  # route_table_key} plus any explicit entries - same idiom as
  # terraform-azurerm-compeer-platform-connectivity's hub subnets.
  derived_nsg_associations = var.identity_vnet == null ? {} : {
    for k, s in var.identity_vnet.subnets : k => { subnet_key = k, nsg_key = s.nsg_key }
    if try(s.nsg_key, null) != null
  }
  derived_route_table_associations = var.identity_vnet == null ? {} : {
    for k, s in var.identity_vnet.subnets : k => { subnet_key = k, route_table_key = s.route_table_key }
    if try(s.route_table_key, null) != null
  }
  effective_nsg_associations         = merge(local.derived_nsg_associations, var.subnet_nsg_associations)
  effective_route_table_associations = merge(local.derived_route_table_associations, var.subnet_route_table_associations)
}

module "subnet_nsg_associations" {
  source   = "../../modules/terraform-azurerm-compeer-nsg-subnet-association"
  for_each = local.effective_nsg_associations

  subnet_id                 = module.identity_vnet[0].subnet_ids[each.value.subnet_key]
  network_security_group_id = module.network_security_groups[each.value.nsg_key].id
}

module "subnet_route_table_associations" {
  source   = "../../modules/terraform-azurerm-compeer-subnet-route-table-association"
  for_each = local.effective_route_table_associations

  subnet_id      = module.identity_vnet[0].subnet_ids[each.value.subnet_key]
  route_table_id = module.route_tables[each.value.route_table_key].id
}

module "recovery_services_vaults" {
  source   = "../../modules/terraform-azurerm-compeer-recovery-services-vault"
  for_each = var.recovery_services_vaults

  name                               = each.value.name
  resource_group_name                = module.resource_group.name
  location                           = module.resource_group.location
  sku                                = each.value.sku
  storage_mode_type                  = each.value.storage_mode_type
  public_network_access_enabled      = try(each.value.public_network_access_enabled, null)
  immutability                       = try(each.value.immutability, null)
  cross_region_restore_enabled       = try(each.value.cross_region_restore_enabled, null)
  classic_vmware_replication_enabled = try(each.value.classic_vmware_replication_enabled, null)
  identity                           = try(each.value.identity, null)
  encryption                         = try(each.value.encryption, null)
  monitoring                         = try(each.value.monitoring, null)
  backup_policy_vm                   = try(each.value.backup_policy_vm, {})
  backup_policy_file_share           = try(each.value.backup_policy_file_share, {})
  timeouts                           = try(each.value.timeouts, {})
  tags                               = module.tags.tags
}

locals {
  default_windows_image = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  # subnet_id wins when a caller sets it explicitly (e.g. a not-yet-migrated
  # hub placement); otherwise resolve subnet_key against this pattern's own
  # identity_vnet. Only network_interfaces (below) needs the resolved value -
  # every other var.domain_controllers reference in this file is unaffected
  # by subnet placement.
  resolved_domain_controllers = {
    for key, controller in var.domain_controllers : key => merge(controller, {
      subnet_id = coalesce(
        try(controller.subnet_id, null),
        try(module.identity_vnet[0].subnet_ids[controller.subnet_key], null)
      )
    })
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
  for_each = local.resolved_domain_controllers

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
  automatic_updates_enabled  = try(each.value.automatic_updates_enabled, try(each.value.enable_automatic_updates, true))
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
    if coalesce(try(controller.diagnostics.enabled, null), false) && anytrue([
      try(controller.diagnostics.log_analytics_workspace_id, null) != null,
      try(controller.diagnostics.storage_account_id, null) != null,
      try(controller.diagnostics.eventhub_authorization_rule_id, null) != null,
      try(controller.diagnostics.partner_solution_id, null) != null,
    ])
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

locals {
  management_lock_inputs = {
    for key, value in var.management_locks : key => {
      name       = value.name
      scope      = coalesce(try(value.scope, null), try(local.scope_ids[value.scope_key], null))
      lock_level = try(value.lock_level, "CanNotDelete")
      notes      = try(value.notes, null)
    }
  }
}

module "management_locks" {
  source = "../../modules/terraform-azurerm-compeer-management-locks"

  locks = local.management_lock_inputs
}

module "operational_contracts" {
  source = "../../modules/terraform-azurerm-compeer-operational-contracts"

  contracts = var.operational_contracts
}

locals {
  dc_backup_policy_key        = try(var.dc_backup.backup_policy_key, null)
  dc_backup_default_policy_id = try(coalesce(try(var.dc_backup.default_backup_policy_id, null), try(module.recovery_services_vaults["identity"].backup_policy_vm_ids[local.dc_backup_policy_key], null)), null)
}

resource "terraform_data" "dc_backup_contract" {
  count = var.dc_backup == null ? 0 : 1

  input = {
    vault_name            = try(coalesce(try(var.dc_backup.vault_name, null), try(module.recovery_services_vaults["identity"].name, null)), null)
    vault_resource_group  = coalesce(try(var.dc_backup.vault_resource_group_name, null), module.resource_group.name)
    protected_controllers = sort(keys(var.dc_backup.protected_controllers))
  }

  lifecycle {
    precondition {
      condition     = alltrue([for key in keys(var.dc_backup.protected_controllers) : contains(keys(var.domain_controllers), key)])
      error_message = "dc_backup.protected_controllers keys must match domain_controllers keys."
    }
    precondition {
      condition = local.dc_backup_default_policy_id != null || alltrue([
        for item in values(var.dc_backup.protected_controllers) : try(item.backup_policy_id, null) != null
      ])
      error_message = "dc_backup must set backup_policy_key/default_backup_policy_id, or every protected_controllers entry must set backup_policy_id."
    }
  }
}

# Tier-0 backup enrolment (deploy-runbook.tf §12: DCs "must be covered by an
# AD-aware recovery procedure"). By default this uses the identity-subscription
# Recovery Services vault created by this pattern.
resource "azurerm_backup_protected_vm" "dc" {
  for_each = var.dc_backup == null ? {} : var.dc_backup.protected_controllers

  # Defaults to this pattern's own recovery_services_vaults["identity"] (the
  # dedicated identity-subscription vault) when dc_backup doesn't name an
  # external vault explicitly - see dc_backup's description.
  resource_group_name = coalesce(try(var.dc_backup.vault_resource_group_name, null), module.resource_group.name)
  recovery_vault_name = coalesce(try(var.dc_backup.vault_name, null), try(module.recovery_services_vaults["identity"].name, null))
  source_vm_id        = module.domain_controllers[each.key].id
  backup_policy_id    = coalesce(try(each.value.backup_policy_id, null), local.dc_backup_default_policy_id)

  depends_on = [terraform_data.dc_backup_contract]
}
