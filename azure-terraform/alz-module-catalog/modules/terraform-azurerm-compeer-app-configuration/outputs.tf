output "app_config_id" {
  description = "App Configuration resource ID."
  value       = azurerm_app_configuration.app_config.id
}
output "app_config_name" {
  description = "App Configuration name."
  value       = azurerm_app_configuration.app_config.name
}
output "app_config_endpoint" {
  description = "App Configuration endpoint."
  value       = azurerm_app_configuration.app_config.endpoint
}
output "identity" {
  description = "Managed identity block."
  value       = azurerm_app_configuration.app_config.identity
}

output "id" {
  description = "Resource ID of the App Configuration store. Stable alias for app_config_id."
  value       = azurerm_app_configuration.app_config.id
}
output "name" {
  description = "Name of the App Configuration store. Stable alias for app_config_name."
  value       = azurerm_app_configuration.app_config.name
}
output "endpoint" {
  description = "Endpoint URL of the App Configuration store. Stable alias for app_config_endpoint."
  value       = azurerm_app_configuration.app_config.endpoint
}
output "identity_principal_id" {
  description = "Principal ID of the store's system-assigned managed identity (null if none), for RBAC grants."
  value       = try(azurerm_app_configuration.app_config.identity[0].principal_id, null)
}
