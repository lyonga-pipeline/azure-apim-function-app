output "resource_group_name" {
  value = module.resource_group.name
}

output "expressroute_circuit_ids" {
  value = { for key, value in module.expressroute_circuits : key => value.id }
}

output "expressroute_gateway_id" {
  value = try(module.expressroute_gateway[0].id, null)
}

output "expressroute_connection_ids" {
  value = { for key, value in module.expressroute_connections : key => value.id }
}

output "expressroute_posture" {
  value = terraform_data.expressroute_contract.output
}

output "vpn_posture" {
  value = terraform_data.vpn_contract.output
}

output "vpn_gateway_public_ip_ids" {
  value = { for key, value in module.vpn_gateway_public_ips : key => value.id }
}

output "vpn_gateway_id" {
  value = try(module.vpn_gateway[0].id, null)
}

output "local_network_gateway_ids" {
  value = module.local_network_gateways.ids
}

output "local_network_gateways" {
  value = module.local_network_gateways.gateways
}

output "vpn_connection_ids" {
  value = { for key, value in module.vpn_connections : key => value.id }
}
