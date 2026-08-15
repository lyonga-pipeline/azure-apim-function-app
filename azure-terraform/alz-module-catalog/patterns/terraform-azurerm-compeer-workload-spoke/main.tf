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

  name                = var.spoke_vnet.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = var.spoke_vnet.address_space
  dns_servers         = try(var.spoke_vnet.dns_servers, null)
  subnets             = var.spoke_vnet.subnets
  tags                = module.tags.tags
}

module "network_security_groups" {
  source   = "../../modules/terraform-azurerm-compeer-network-security-group"
  for_each = var.network_security_groups

  name                = each.value.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_id = coalesce(
    try(each.value.subnet_id, null),
    try(module.spoke_vnet.subnet_ids[each.value.subnet_key], null),
    "/subscriptions/${var.subscription_id}/resourceGroups/${module.resource_group.name}/providers/Microsoft.Network/virtualNetworks/${module.spoke_vnet.name}/subnets/${try(each.value.subnet_key, each.key)}"
  )
  security_rule = [
    for name, rule in try(each.value.rules, {}) : {
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
  ]
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

locals {
  workload_scope_ids = merge(
    {
      resource_group = module.resource_group.id
      spoke_vnet     = module.spoke_vnet.id
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
