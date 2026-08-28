output "resource_group_name" {
  value = try(module.hybrid_connectivity[0].resource_group_name, null)
}

output "expressroute_posture" {
  value = try(module.hybrid_connectivity[0].expressroute_posture, null)
}

output "expressroute_circuit_ids" {
  value = try(module.hybrid_connectivity[0].expressroute_circuit_ids, {})
}

output "expressroute_gateway_id" {
  value = try(module.hybrid_connectivity[0].expressroute_gateway_id, null)
}

output "expressroute_connection_ids" {
  value = try(module.hybrid_connectivity[0].expressroute_connection_ids, {})
}

output "vpn_posture" {
  value = try(module.hybrid_connectivity[0].vpn_posture, null)
}

output "vpn_gateway_public_ip_ids" {
  value = try(module.hybrid_connectivity[0].vpn_gateway_public_ip_ids, {})
}

output "vpn_gateway_id" {
  value = try(module.hybrid_connectivity[0].vpn_gateway_id, null)
}

output "local_network_gateway_ids" {
  value = try(module.hybrid_connectivity[0].local_network_gateway_ids, {})
}

output "local_network_gateways" {
  value = try(module.hybrid_connectivity[0].local_network_gateways, {})
}

output "vpn_connection_ids" {
  value = try(module.hybrid_connectivity[0].vpn_connection_ids, {})
}
