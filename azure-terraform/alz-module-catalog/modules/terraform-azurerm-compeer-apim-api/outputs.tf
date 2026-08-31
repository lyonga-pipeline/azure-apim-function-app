output "api_id" {
  value       = azurerm_api_management_api.api.id
  description = "The ID of the API Management Service API's."
}

output "api_name" {
  value = azurerm_api_management_api.api.name
}
