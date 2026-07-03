output "hub_to_spoke_peering_id" {
  value = module.hub_to_spoke_peering.id
}

output "spoke_to_hub_peering_id" {
  value = module.spoke_to_hub_peering.id
}

output "private_dns_spoke_link_ids" {
  value = module.private_dns_spoke_links.ids
}

output "resolved_hub_virtual_network_id" {
  value = local.hub_virtual_network_id
}

output "resolved_spoke_virtual_network_id" {
  value = local.spoke_virtual_network_id
}
