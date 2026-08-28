output "expressroute_circuit_ids" {
  value = { for key, circuit in module.expressroute_circuit : key => circuit.id }
}

output "expressroute_circuit_service_keys" {
  value     = { for key, circuit in module.expressroute_circuit : key => circuit.service_key }
  sensitive = true
}

output "expressroute_peering_ids" {
  value = { for key, peering in azurerm_express_route_circuit_peering.this : key => peering.id }
}

output "expressroute_authorization_ids" {
  value = { for key, authorization in azurerm_express_route_circuit_authorization.this : key => authorization.id }
}

output "expressroute_authorization_keys" {
  value     = { for key, authorization in azurerm_express_route_circuit_authorization.this : key => authorization.authorization_key }
  sensitive = true
}

output "gateway_connection_ids" {
  value = { for key, connection in module.gateway_connection : key => connection.id }
}
