output "api_id" {
  value       = azurerm_api_management_api.api.id
  description = "The ID of the API Management Service API's."
}

output "api_name" {
  description = "Name of the API Management API."
  value       = azurerm_api_management_api.api.name
}

output "id" {
  description = "Resource ID of the API Management API. Stable alias for api_id."
  value       = azurerm_api_management_api.api.id
}
output "name" {
  description = "Name of the API Management API. Stable alias for api_name."
  value       = azurerm_api_management_api.api.name
}
