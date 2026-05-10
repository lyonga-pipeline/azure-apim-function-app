output "id" { value = azurerm_network_interface.this.id }
output "ip_configuration_ids" {
  value = azurerm_network_interface.this.ip_configuration[*].id
}
