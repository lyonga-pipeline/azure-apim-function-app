output "id" { value = azurerm_servicebus_namespace.main.id }
output "name" { value = azurerm_servicebus_namespace.main.name }
output "identity" { value = azurerm_servicebus_namespace.main.identity }
output "default_primary_connection_string" {
  value     = azurerm_servicebus_namespace.main.default_primary_connection_string
  sensitive = true
}
output "default_secondary_connection_string" {
  value     = azurerm_servicebus_namespace.main.default_secondary_connection_string
  sensitive = true
}
