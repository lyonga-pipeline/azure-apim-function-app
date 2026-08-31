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
