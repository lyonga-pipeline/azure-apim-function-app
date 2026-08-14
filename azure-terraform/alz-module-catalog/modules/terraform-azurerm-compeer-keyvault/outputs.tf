###################################
## Azure Vault Realated Attributes
##################################
output "key_vault_id" {
  description = "The ID of the Key Vault."
  value       = azurerm_key_vault.keyvault.id
}

output "key_vault_name" {
  description = "The name of the Key Vault."
  value       = azurerm_key_vault.keyvault.name
}

output "key_vault_uri" {
  description = "The URI of the Key Vault, used for performing operations on keys and secrets."
  value       = azurerm_key_vault.keyvault.vault_uri
}

output "rbac_authorization_enabled" {
  description = "Whether Azure RBAC authorization is enabled for the vault."
  value       = azurerm_key_vault.keyvault.rbac_authorization_enabled
}
