output "id" {
  description = "Resource ID of the application gateway."
  value       = azurerm_application_gateway.gateway.id
}
output "frontend_ip_configuration" {
  description = "Frontend IP configuration blocks of the application gateway (name, subnet_id, private/public IP association)."
  value       = azurerm_application_gateway.gateway.frontend_ip_configuration
}
