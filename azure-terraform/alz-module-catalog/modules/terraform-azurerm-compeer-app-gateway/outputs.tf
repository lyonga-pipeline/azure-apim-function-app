output "id" {
  description = "Resource ID of the Application Gateway."
  value       = azurerm_application_gateway.main.id
}

output "name" {
  description = "Name of the Application Gateway."
  value       = azurerm_application_gateway.main.name
}

output "frontend_ip_configuration" {
  description = "Frontend IP configuration blocks."
  value       = azurerm_application_gateway.main.frontend_ip_configuration
}

output "backend_address_pool_ids" {
  description = "Map of backend pool name => id."
  value       = { for p in azurerm_application_gateway.main.backend_address_pool : p.name => p.id }
}

output "identity_principal_id" {
  description = "Principal ID of the gateway's identity, when set."
  value       = try(azurerm_application_gateway.main.identity[0].principal_id, null)
}
