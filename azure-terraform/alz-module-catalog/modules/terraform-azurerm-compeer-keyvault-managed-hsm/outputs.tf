/**
## Azure Key Vault Managed HSM Attributes
*/
output "key_vault_hsm_id" {
  description = "The Key Vault Secret Managed Hardware Security Module ID."
  value       = azurerm_key_vault_managed_hardware_security_module.managed_hsm.id
}
output "key_vault_hsm_uri" {
  description = "The URI of the Key Vault Managed Hardware Security Module, used for performing operations on keys."
  value       = azurerm_key_vault_managed_hardware_security_module.managed_hsm.hsm_uri
}
output "key_vault_hsm_security_domain_encrypted_data" {
  description = "This attribute can be used for disaster recovery or when creating another Managed HSM that shares the same security domain."
  value       = azurerm_key_vault_managed_hardware_security_module.managed_hsm.security_domain_encrypted_data
}
