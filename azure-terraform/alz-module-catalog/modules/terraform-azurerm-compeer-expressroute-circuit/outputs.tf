output "id" { value = azurerm_express_route_circuit.this.id }
output "name" { value = azurerm_express_route_circuit.this.name }
output "service_key" {
  value     = azurerm_express_route_circuit.this.service_key
  sensitive = true
}
