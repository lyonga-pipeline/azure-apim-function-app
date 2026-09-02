output "id" {
  description = "Resource ID of the Service Bus namespace."
  value       = azurerm_servicebus_namespace.main.id
}
output "name" {
  description = "Name of the Service Bus namespace."
  value       = azurerm_servicebus_namespace.main.name
}
output "identity" {
  description = "Managed identity block of the namespace (type, principal_id, tenant_id)."
  value       = azurerm_servicebus_namespace.main.identity
}
output "default_primary_connection_string" {
  description = "Primary connection string for the namespace RootManageSharedAccessKey (sensitive; prefer managed identity)."
  value       = azurerm_servicebus_namespace.main.default_primary_connection_string
  sensitive   = true
}
output "default_secondary_connection_string" {
  description = "Secondary connection string for the namespace RootManageSharedAccessKey (sensitive; prefer managed identity)."
  value       = azurerm_servicebus_namespace.main.default_secondary_connection_string
  sensitive   = true
}
