output "apim_id" {
  value       = azurerm_api_management.apim.id
  description = "The ID of the API Management Service."
}

output "apim_principal_id" {
  value       = azurerm_api_management.apim.identity.0.principal_id
  description = "The Principal ID of the APIM Identity"
}

output "apim_tenant_id" {
  value       = azurerm_api_management.apim.identity.0.tenant_id
  description = "The Tenant ID of the APIM Identity"
}