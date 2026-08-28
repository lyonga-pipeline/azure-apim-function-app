output "hub_to_spoke_peering_id" {
  value = try(module.network_peering[0].hub_to_spoke_peering_id, null)
}

output "spoke_to_hub_peering_id" {
  value = try(module.network_peering[0].spoke_to_hub_peering_id, null)
}

output "private_dns_spoke_link_ids" {
  value = try(module.network_peering[0].private_dns_spoke_link_ids, {})
}
