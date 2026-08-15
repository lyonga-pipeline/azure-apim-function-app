output "identity_aad_id" {
  value       = azurerm_api_management_identity_provider_aad.apim_identity_provider_aad[0].id
  description = "The ID of the API Management AAD Identity Provider."
}

output "identity_aadb2c_id" {
  value       = azurerm_api_management_identity_provider_aadb2c.apim_identity_provider_aadb2c[0].id
  description = "The ID of the API Management Azure AD B2C Identity Provider Resource."
}