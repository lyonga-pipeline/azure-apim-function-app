output "openid_id" {
  value       = azurerm_api_management_openid_connect_provider.apim_openid_connect_provider.id
  description = "The ID of the API Management OpenID Connect Provider."
}

output "id" {
  description = "Resource ID of the API Management OpenID Connect provider. Stable alias for openid_id."
  value       = azurerm_api_management_openid_connect_provider.apim_openid_connect_provider.id
}
output "name" {
  description = "Name of the API Management OpenID Connect provider."
  value       = azurerm_api_management_openid_connect_provider.apim_openid_connect_provider.name
}
