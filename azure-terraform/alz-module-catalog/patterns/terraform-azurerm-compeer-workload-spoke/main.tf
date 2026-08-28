module "tags" {
  source = "../../modules/terraform-azurerm-compeer-platform-tags"

  environment         = var.environment
  application         = var.workload_tags.application
  business_owner      = var.workload_tags.business_owner
  source_repo         = var.workload_tags.source_repo
  terraform_workspace = var.workload_tags.terraform_workspace
  recovery_tier       = var.workload_tags.recovery_tier
  cost_center         = var.workload_tags.cost_center
  data_classification = var.workload_tags.data_classification
  compliance_boundary = var.workload_tags.compliance_boundary
  additional_tags     = var.workload_tags.additional_tags
}

module "resource_group" {
  source = "../../modules/terraform-azurerm-compeer-resource-group"

  name     = var.resource_group.name
  location = var.location
  tags     = module.tags.tags
}

module "spoke_vnet" {
  source = "../../modules/terraform-azurerm-compeer-virtual-network"

  name                           = var.spoke_vnet.name
  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  address_space                  = var.spoke_vnet.address_space
  dns_servers                    = try(var.spoke_vnet.dns_servers, null)
  bgp_community                  = try(var.spoke_vnet.bgp_community, null)
  edge_zone                      = try(var.spoke_vnet.edge_zone, null)
  flow_timeout_in_minutes        = try(var.spoke_vnet.flow_timeout_in_minutes, null)
  private_endpoint_vnet_policies = try(var.spoke_vnet.private_endpoint_vnet_policies, null)
  subnets                        = var.spoke_vnet.subnets
  encryption                     = try(var.spoke_vnet.encryption, null)
  ip_address_pools               = try(var.spoke_vnet.ip_address_pools, {})
  timeouts                       = try(var.spoke_vnet.timeouts, {})
  tags                           = module.tags.tags
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

module "subnet_nsg_associations" {
  source   = "../../modules/terraform-azurerm-compeer-nsg-subnet-association"
  for_each = var.subnet_nsg_associations

  subnet_id                 = module.spoke_vnet.subnet_ids[each.value.subnet_key]
  network_security_group_id = module.network_security_groups[each.value.nsg_key].id
}

module "route_tables" {
  source   = "../../modules/terraform-azurerm-compeer-route-table"
  for_each = var.route_tables

  name                          = each.value.name
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  bgp_route_propagation_enabled = each.value.bgp_route_propagation_enabled
  routes                        = each.value.routes
  tags                          = module.tags.tags
}

module "subnet_route_table_associations" {
  source   = "../../modules/terraform-azurerm-compeer-subnet-route-table-association"
  for_each = var.subnet_route_table_associations

  subnet_id      = module.spoke_vnet.subnet_ids[each.value.subnet_key]
  route_table_id = module.route_tables[each.value.route_table_key].id
}

module "spoke_to_hub_peering" {
  source = "../../modules/terraform-azurerm-compeer-vnet-peering"
  count  = var.hub_connection == null ? 0 : 1

  peering_name                 = "peer-${var.spoke_vnet.name}-to-hub"
  rg_name                      = module.resource_group.name
  vnet_name                    = module.spoke_vnet.name
  remote_virtual_network_id    = var.hub_connection.hub_virtual_network_id
  allow_forwarded_traffic      = var.hub_connection.allow_forwarded_traffic
  allow_gateway_transit        = var.hub_connection.allow_gateway_transit
  use_remote_gateways          = var.hub_connection.use_remote_gateways
  allow_virtual_network_access = true
}

module "private_dns_spoke_links" {
  source = "../../modules/terraform-azurerm-compeer-private-dns-vnet-link"

  links = {
    for key, zone in var.private_dns_zone_links : key => {
      name                  = "lnk-${key}-${var.environment}-${var.workload_tags.application}"
      resource_group_name   = zone.resource_group_name
      private_dns_zone_name = zone.private_dns_zone_name
      virtual_network_id    = module.spoke_vnet.id
      registration_enabled  = zone.registration_enabled
      tags                  = module.tags.tags
    }
  }
  tags = module.tags.tags
}

module "workload_identity" {
  source = "../../modules/terraform-azurerm-compeer-user-assigned-identity"
  count  = coalesce(try(var.workload_identity.enabled, null), false) ? 1 : 0

  name                = coalesce(try(var.workload_identity.name, null), "${var.spoke_vnet.name}-uami")
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = module.tags.tags
}

module "workload_key_vault" {
  source = "../../modules/terraform-azurerm-compeer-keyvault"
  count  = coalesce(try(var.workload_key_vault.enabled, null), false) ? 1 : 0

  name                        = var.workload_key_vault.name
  resource_group_name         = module.resource_group.name
  location                    = module.resource_group.location
  tenant_id                   = var.tenant_id
  sku_name                    = try(var.workload_key_vault.sku_name, "premium")
  soft_delete_retention_days  = try(var.workload_key_vault.soft_delete_retention_days, 90)
  purge_protection_enabled    = try(var.workload_key_vault.purge_protection_enabled, true)
  rbac_authorization_enabled  = try(var.workload_key_vault.rbac_authorization_enabled, true)
  access_policies             = try(var.workload_key_vault.access_policies, [])
  access_policies_by_key      = try(var.workload_key_vault.access_policies_by_key, {})
  enabled_for_deployment      = try(var.workload_key_vault.enabled_for_deployment, false)
  enabled_for_disk_encryption = try(var.workload_key_vault.enabled_for_disk_encryption, true)
  enabled_for_template_deployment = try(
    var.workload_key_vault.enabled_for_template_deployment,
    false
  )
  public_network_access_enabled = try(var.workload_key_vault.public_network_access_enabled, false)
  network_acls = coalesce(try(var.workload_key_vault.network_acls, null), {
    bypass         = "AzureServices"
    default_action = "Deny"
  })
  contacts = values(try(var.workload_key_vault.contacts, {}))
  timeouts = try(var.workload_key_vault.timeouts, {})
  tags     = module.tags.tags
}

locals {
  workload_key_vault_role_assignment_inputs = coalesce(try(var.workload_key_vault.enabled, null), false) ? merge(
    coalesce(try(var.workload_identity.enabled, null), false) ? {
      workload_identity_secrets_user = {
        scope                = module.workload_key_vault[0].id
        principal_id         = module.workload_identity[0].principal_id
        role_definition_name = "Key Vault Secrets User"
        principal_type       = "ServicePrincipal"
      }
    } : {},
    {
      for key, assignment in try(var.workload_key_vault.role_assignments, {}) : key => merge(assignment, {
        scope = coalesce(try(assignment.scope, null), module.workload_key_vault[0].id)
      })
    }
  ) : {}
}

module "workload_key_vault_role_assignments" {
  source = "../../modules/terraform-azurerm-compeer-role-assignments"

  assignments = local.workload_key_vault_role_assignment_inputs
}

module "workload_key_vault_diagnostics" {
  source = "../../modules/terraform-azurerm-compeer-diagnostic-settings"
  count = (
    coalesce(try(var.workload_key_vault.enabled, null), false) &&
    coalesce(try(var.workload_key_vault.diagnostics.enabled, null), true) &&
    try(var.workload_key_vault.diagnostics.log_analytics_workspace_id, null) != null
  ) ? 1 : 0

  name                           = coalesce(try(var.workload_key_vault.diagnostics.name, null), "${var.workload_key_vault.name}-diag")
  target_resource_id             = module.workload_key_vault[0].id
  log_analytics_workspace_id     = var.workload_key_vault.diagnostics.log_analytics_workspace_id
  log_analytics_destination_type = try(var.workload_key_vault.diagnostics.log_analytics_destination_type, null)
  storage_account_id             = try(var.workload_key_vault.diagnostics.storage_account_id, null)
  eventhub_authorization_rule_id = try(
    var.workload_key_vault.diagnostics.eventhub_authorization_rule_id,
    null
  )
  eventhub_name       = try(var.workload_key_vault.diagnostics.eventhub_name, null)
  partner_solution_id = try(var.workload_key_vault.diagnostics.partner_solution_id, null)
  logs                = try(var.workload_key_vault.diagnostics.logs, { all = { category_group = "allLogs" } })
  metrics             = try(var.workload_key_vault.diagnostics.metrics, { all = { category = "AllMetrics" } })
}

module "workload_key_vault_private_endpoint" {
  source = "../../modules/terraform-azurerm-compeer-private-endpoint"
  count  = coalesce(try(var.workload_key_vault.enabled, null), false) && try(var.workload_key_vault.private_endpoint, null) != null ? 1 : 0

  name                          = var.workload_key_vault.private_endpoint.name
  custom_network_interface_name = try(var.workload_key_vault.private_endpoint.custom_network_interface_name, null)
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  edge_zone                     = try(var.workload_key_vault.private_endpoint.edge_zone, null)
  subnet_id                     = coalesce(try(var.workload_key_vault.private_endpoint.subnet_id, null), try(module.spoke_vnet.subnet_ids[var.workload_key_vault.private_endpoint.subnet_key], null), try(module.spoke_vnet.subnet_ids["private_endpoints"], null))
  private_service_connections = [
    {
      name                           = coalesce(try(var.workload_key_vault.private_endpoint.private_service_connection_name, null), "${var.workload_key_vault.private_endpoint.name}-psc")
      is_manual_connection           = false
      private_connection_resource_id = module.workload_key_vault[0].id
      subresource_names              = ["vault"]
    }
  ]
  private_dns_zone_group = length(try(var.workload_key_vault.private_endpoint.private_dns_zone_ids, [])) == 0 ? [] : [
    {
      name                 = coalesce(try(var.workload_key_vault.private_endpoint.private_dns_zone_group_name, null), "default")
      private_dns_zone_ids = var.workload_key_vault.private_endpoint.private_dns_zone_ids
    }
  ]
  ip_configurations = try(var.workload_key_vault.private_endpoint.ip_configurations, [])
  timeouts          = try(var.workload_key_vault.private_endpoint.timeouts, {})
  tags              = module.tags.tags
}

locals {
  workload_scope_ids = merge(
    {
      resource_group = module.resource_group.id
      spoke_vnet     = module.spoke_vnet.id
    },
    length(module.workload_identity) == 0 ? {} : {
      workload_identity = module.workload_identity[0].id
    },
    length(module.workload_key_vault) == 0 ? {} : {
      workload_key_vault = module.workload_key_vault[0].id
    },
    {
      for key, value in module.network_security_groups : "nsg:${key}" => value.id
    },
    {
      for key, value in module.route_tables : "route_table:${key}" => value.id
    },
    var.additional_scopes
  )

  role_assignment_inputs = {
    for key, assignment in var.role_assignments : key => merge(assignment, {
      scope = coalesce(
        try(assignment.scope, null),
        try(local.workload_scope_ids[assignment.scope_key], null)
      )
    })
  }
}

module "role_assignments" {
  source = "../../modules/terraform-azurerm-compeer-role-assignments"

  assignments = local.role_assignment_inputs
}

resource "azurerm_management_lock" "this" {
  for_each = var.management_locks

  name       = each.value.name
  scope      = coalesce(try(each.value.scope, null), try(local.workload_scope_ids[each.value.scope_key], null))
  lock_level = each.value.lock_level
  notes      = try(each.value.notes, null)
}

module "diagnostic_settings" {
  source   = "../../modules/terraform-azurerm-compeer-diagnostic-settings"
  for_each = var.diagnostic_settings

  name                       = each.value.name
  target_resource_id         = coalesce(try(each.value.target_resource_id, null), try(local.workload_scope_ids[each.value.target_key], null))
  log_analytics_workspace_id = each.value.log_analytics_workspace_id
  storage_account_id         = try(each.value.storage_account_id, null)
  eventhub_authorization_rule_id = try(
    each.value.eventhub_authorization_rule_id,
    null
  )
  eventhub_name       = try(each.value.eventhub_name, null)
  partner_solution_id = try(each.value.partner_solution_id, null)
  logs                = each.value.logs
  metrics             = each.value.metrics
}
