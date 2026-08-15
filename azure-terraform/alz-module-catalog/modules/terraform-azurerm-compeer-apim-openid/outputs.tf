output "openid_id" {
  value       = azurerm_api_management_openid_connect_provider.apim_openid_connect_provider.id
  description = "The ID of the API Management OpenID Connect Provider."
}