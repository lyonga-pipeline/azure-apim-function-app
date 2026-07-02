locals {
  private_dns_zone_links = {
    for key, zone in var.private_dns_zones : key => {
      name                  = coalesce(try(zone.link_name, null), "lnk-${key}-${var.peering_name_prefix}-spoke")
      resource_group_name   = coalesce(try(zone.resource_group_name, null), var.private_dns_zone_resource_group_name)
      private_dns_zone_name = zone.name
      virtual_network_id    = var.spoke_virtual_network_id
      registration_enabled  = try(zone.registration_enabled, false)
      tags                  = var.tags
    }
    if try(zone.link_to_spoke_enabled, true)
  }
}

module "hub_to_spoke_peering" {
  source = "../../../modules/vnet-peering"

  providers = {
    azurerm = azurerm.hub
  }

  name                         = "peer-${var.peering_name_prefix}-hub-to-spoke"
  resource_group_name          = var.hub_resource_group_name
  virtual_network_name         = var.hub_virtual_network_name
  remote_virtual_network_id    = var.spoke_virtual_network_id
  allow_virtual_network_access = var.hub_to_spoke.allow_virtual_network_access
  allow_forwarded_traffic      = var.hub_to_spoke.allow_forwarded_traffic
  allow_gateway_transit        = var.hub_to_spoke.allow_gateway_transit
  use_remote_gateways          = var.hub_to_spoke.use_remote_gateways
}

module "spoke_to_hub_peering" {
  source = "../../../modules/vnet-peering"

  providers = {
    azurerm = azurerm.spoke
  }

  name                         = "peer-${var.peering_name_prefix}-spoke-to-hub"
  resource_group_name          = var.spoke_resource_group_name
  virtual_network_name         = var.spoke_virtual_network_name
  remote_virtual_network_id    = var.hub_virtual_network_id
  allow_virtual_network_access = var.spoke_to_hub.allow_virtual_network_access
  allow_forwarded_traffic      = var.spoke_to_hub.allow_forwarded_traffic
  allow_gateway_transit        = var.spoke_to_hub.allow_gateway_transit
  use_remote_gateways          = var.spoke_to_hub.use_remote_gateways
}

module "private_dns_spoke_links" {
  source = "../../../modules/private-dns-vnet-link"

  providers = {
    azurerm = azurerm.hub
  }

  links = local.private_dns_zone_links
  tags  = var.tags

  depends_on = [
    module.hub_to_spoke_peering,
    module.spoke_to_hub_peering,
  ]
}
