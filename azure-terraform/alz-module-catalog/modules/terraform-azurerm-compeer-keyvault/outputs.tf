###################################
## Azure Vault Realated Attributes
##################################
output "key_vault_id" {
  description = "The ID of the Key Vault."
  value       = azurerm_key_vault.keyvault.id
}

output "id" {
  description = "The ID of the Key Vault."
  value       = azurerm_key_vault.keyvault.id
}

output "key_vault_name" {
  description = "The name of the Key Vault."
  value       = azurerm_key_vault.keyvault.name
}

output "name" {
  description = "The name of the Key Vault."
  value       = azurerm_key_vault.keyvault.name
}

output "key_vault_uri" {
  description = "The URI of the Key Vault, used for performing operations on keys and secrets."
  value       = azurerm_key_vault.keyvault.vault_uri
}

output "vault_uri" {
  description = "The URI of the Key Vault, used for performing operations on keys and secrets."
  value       = azurerm_key_vault.keyvault.vault_uri
}

output "rbac_authorization_enabled" {
  description = "Whether Azure RBAC authorization is enabled for the vault."
  value       = azurerm_key_vault.keyvault.rbac_authorization_enabled
}

output "resource_group_name" {
  description = "The resource group containing the Key Vault."
  value       = azurerm_key_vault.keyvault.resource_group_name
}

output "location" {
  description = "The Azure region of the Key Vault."
  value       = azurerm_key_vault.keyvault.location
}

output "tenant_id" {
  description = "The tenant ID configured on the Key Vault."
  value       = azurerm_key_vault.keyvault.tenant_id
}

output "sku_name" {
  description = "The configured Key Vault SKU."
  value       = azurerm_key_vault.keyvault.sku_name
}

output "private_endpoint_ready_subresource_names" {
  description = "Common Private Endpoint subresource names exposed for composition by pattern modules."
  value       = ["vault"]
}
