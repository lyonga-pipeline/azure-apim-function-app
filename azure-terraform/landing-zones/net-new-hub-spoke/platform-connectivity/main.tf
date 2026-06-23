module "tags" {
  source = "../../../modules/platform-tags"

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
  source = "../../../modules/resource-group"

  name     = var.resource_group.name
  location = var.location
  tags     = module.tags.tags
}

module "hub_vnet" {
  source = "../../../modules/virtual-network"

  name                = var.hub_vnet.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = var.hub_vnet.address_space
  dns_servers         = try(var.hub_vnet.dns_servers, null)
  subnets             = var.hub_vnet.subnets
  tags                = module.tags.tags
}

module "network_security_groups" {
  source   = "../../../modules/network-security-group"
  for_each = var.network_security_groups

  name                = each.value.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  rules               = each.value.rules
  tags                = module.tags.tags
}

module "subnet_nsg_associations" {
  source   = "../../../modules/nsg-subnet-association"
  for_each = var.subnet_nsg_associations

  subnet_id                 = module.hub_vnet.subnet_ids[each.value.subnet_key]
  network_security_group_id = module.network_security_groups[each.value.nsg_key].id
}

module "route_tables" {
  source   = "../../../modules/route-table"
  for_each = var.route_tables

  name                          = each.value.name
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  bgp_route_propagation_enabled = each.value.bgp_route_propagation_enabled
  routes                        = each.value.routes
  tags                          = module.tags.tags
}

module "subnet_route_table_associations" {
  source   = "../../../modules/subnet-route-table-association"
  for_each = var.subnet_route_table_associations

  subnet_id      = module.hub_vnet.subnet_ids[each.value.subnet_key]
  route_table_id = module.route_tables[each.value.route_table_key].id
}

module "private_dns_zones" {
  source = "../../../modules/private-dns-zone"

  zones = {
    for key, zone in var.private_dns_zones : key => {
      name                = zone.name
      resource_group_name = coalesce(try(zone.resource_group_name, null), module.resource_group.name)
      tags                = module.tags.tags
    }
  }
  tags = module.tags.tags
}

module "private_dns_hub_links" {
  source = "../../../modules/private-dns-vnet-link"

  links = {
    for key, zone in var.private_dns_zones : key => {
      name                  = "lnk-${key}-${var.environment}-hub"
      resource_group_name   = coalesce(try(zone.resource_group_name, null), module.resource_group.name)
      private_dns_zone_name = module.private_dns_zones.names[key]
      virtual_network_id    = module.hub_vnet.id
      registration_enabled  = zone.registration_enabled
      tags                  = module.tags.tags
    }
    if zone.link_to_hub
  }
  tags = module.tags.tags
}

locals {
  connectivity_scope_ids = merge(
    {
      resource_group = module.resource_group.id
      hub_vnet       = module.hub_vnet.id
    },
    {
      for key, value in module.network_security_groups : "nsg:${key}" => value.id
    },
    {
      for key, value in module.route_tables : "route_table:${key}" => value.id
    },
    {
      for key, value in module.private_dns_zones.ids : "private_dns_zone:${key}" => value
    },
    var.additional_scopes
  )

  role_assignment_inputs = {
    for key, assignment in var.role_assignments : key => merge(assignment, {
      scope = coalesce(
        try(assignment.scope, null),
        try(local.connectivity_scope_ids[assignment.scope_key], null)
      )
    })
  }
}

module "role_assignments" {
  source = "../../../modules/role-assignments"

  assignments = local.role_assignment_inputs
}

resource "azurerm_management_lock" "this" {
  for_each = var.management_locks

  name       = each.value.name
  scope      = coalesce(try(each.value.scope, null), try(local.connectivity_scope_ids[each.value.scope_key], null))
  lock_level = each.value.lock_level
  notes      = try(each.value.notes, null)
}

module "diagnostic_settings" {
  source   = "../../../modules/diagnostic-settings"
  for_each = var.diagnostic_settings

  name                       = each.value.name
  target_resource_id         = coalesce(try(each.value.target_resource_id, null), try(local.connectivity_scope_ids[each.value.target_key], null))
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
