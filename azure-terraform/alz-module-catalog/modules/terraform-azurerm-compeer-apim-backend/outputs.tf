output "id" {
  description = "Resource ID of the API Management backend."
  value       = azurerm_api_management_backend.apim_backend.id
}

output "name" {
  description = "Name of the API Management backend, referenced by API policies (set-backend-service)."
  value       = azurerm_api_management_backend.apim_backend.name
}
