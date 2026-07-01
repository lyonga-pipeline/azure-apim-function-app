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
