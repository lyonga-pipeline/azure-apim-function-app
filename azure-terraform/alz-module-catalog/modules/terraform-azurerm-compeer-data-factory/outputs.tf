output "data_factory_id" {
  description = "Resource ID of the Data Factory."
  value       = azurerm_data_factory.main_data_factory.id
}
output "data_factory_name" {
  description = "Name of the Data Factory."
  value       = azurerm_data_factory.main_data_factory.name
}
output "data_factory_identity" {
  description = "Managed identity block of the Data Factory (type, principal_id, tenant_id)."
  value       = azurerm_data_factory.main_data_factory.identity
}
output "data_factory_identity_principal_id" {
  description = "Principal ID of the Data Factory's system-assigned managed identity (null if none), for RBAC grants."
  value       = try(azurerm_data_factory.main_data_factory.identity[0].principal_id, null)
}

output "id" {
  description = "Resource ID of the Data Factory. Stable alias for data_factory_id."
  value       = azurerm_data_factory.main_data_factory.id
}
output "name" {
  description = "Name of the Data Factory. Stable alias for data_factory_name."
  value       = azurerm_data_factory.main_data_factory.name
}
