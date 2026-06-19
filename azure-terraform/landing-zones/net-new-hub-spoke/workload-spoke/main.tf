module "tags" {
  source = "../../../modules/platform-tags"

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
  source = "../../../modules/resource-group"

  name     = var.resource_group.name
  location = var.location
  tags     = module.tags.tags
}

module "spoke_vnet" {
  source = "../../../modules/virtual-network"

  name                = var.spoke_vnet.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = var.spoke_vnet.address_space
  dns_servers         = try(var.spoke_vnet.dns_servers, null)
  subnets             = var.spoke_vnet.subnets
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

  subnet_id                 = module.spoke_vnet.subnet_ids[each.value.subnet_key]
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

  subnet_id      = module.spoke_vnet.subnet_ids[each.value.subnet_key]
  route_table_id = module.route_tables[each.value.route_table_key].id
}

module "spoke_to_hub_peering" {
  source = "../../../modules/vnet-peering"
  count  = var.hub_connection == null ? 0 : 1

  name                         = "peer-${var.spoke_vnet.name}-to-hub"
  resource_group_name          = module.resource_group.name
  virtual_network_name         = module.spoke_vnet.name
  remote_virtual_network_id    = var.hub_connection.hub_virtual_network_id
  allow_forwarded_traffic      = var.hub_connection.allow_forwarded_traffic
  allow_gateway_transit        = var.hub_connection.allow_gateway_transit
  use_remote_gateways          = var.hub_connection.use_remote_gateways
  allow_virtual_network_access = true
}

module "private_dns_spoke_links" {
  source = "../../../modules/private-dns-vnet-link"

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

