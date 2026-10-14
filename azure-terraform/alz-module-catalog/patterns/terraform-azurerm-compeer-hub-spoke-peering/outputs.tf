output "hub_to_spoke_peering_id" { value = module.hub_to_spoke_peering.id }
output "spoke_to_hub_peering_id" { value = module.spoke_to_hub_peering.id }
output "private_dns_spoke_link_ids" { value = module.private_dns_spoke_links.ids }
output "peerings" {
  description = "Observed reciprocal configuration; validate actual connectivity separately."
  value = {
    hub_to_spoke = {
      id                        = module.hub_to_spoke_peering.id
      name                      = module.hub_to_spoke_peering.name
      remote_virtual_network_id = module.hub_to_spoke_peering.peering_remote_virtual_network_id
      allow_forwarded_traffic   = module.hub_to_spoke_peering.peering_allow_forwarded_traffic
      allow_gateway_transit     = module.hub_to_spoke_peering.peering_allow_gateway_transit
      use_remote_gateways       = module.hub_to_spoke_peering.peering_use_remote_gateways
    }
    spoke_to_hub = {
      id                        = module.spoke_to_hub_peering.id
      name                      = module.spoke_to_hub_peering.name
      remote_virtual_network_id = module.spoke_to_hub_peering.peering_remote_virtual_network_id
      allow_forwarded_traffic   = module.spoke_to_hub_peering.peering_allow_forwarded_traffic
      allow_gateway_transit     = module.spoke_to_hub_peering.peering_allow_gateway_transit
      use_remote_gateways       = module.spoke_to_hub_peering.peering_use_remote_gateways
    }
  }
}
