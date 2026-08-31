output "identity_aad_id" {
  description = "Resource ID of the AAD identity provider, when managed."
  value       = try(azurerm_api_management_identity_provider_aad.apim_identity_provider_aad["aad"].id, null)
}

output "identity_aadb2c_id" {
  description = "Resource ID of the AAD B2C identity provider, when managed."
  value       = try(azurerm_api_management_identity_provider_aadb2c.apim_identity_provider_aadb2c["aadb2c"].id, null)
}
