output "id" {
  description = "Resource ID of the ExpressRoute circuit."
  value       = azurerm_express_route_circuit.circuit.id
}
output "name" {
  description = "Name of the ExpressRoute circuit."
  value       = azurerm_express_route_circuit.circuit.name
}
output "service_key" {
  description = "Service key of the ExpressRoute circuit, provided to the connectivity provider (sensitive)."
  value       = azurerm_express_route_circuit.circuit.service_key
  sensitive   = true
}
