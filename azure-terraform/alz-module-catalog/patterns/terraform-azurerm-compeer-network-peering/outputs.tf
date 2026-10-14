output "hub_to_spoke_peering_id" {
  value = module.attachment.hub_to_spoke_peering_id
}

output "spoke_to_hub_peering_id" {
  value = module.attachment.spoke_to_hub_peering_id
}

output "private_dns_spoke_link_ids" {
  value = module.attachment.private_dns_spoke_link_ids
}

output "resolved_hub_virtual_network_id" {
  value     = local.hub_virtual_network_id
  sensitive = true
}

output "resolved_spoke_virtual_network_id" {
  value     = local.spoke_virtual_network_id
  sensitive = true
}

output "peerings" {
  description = "Observed reciprocal peering configuration for composition tests and consumers; not proof that routes/services are reachable."
  value       = module.attachment.peerings
}
