output "id" {
  description = "Resource ID of the Key Vault."
  value       = azurerm_key_vault.keyvault.id
}
output "name" {
  description = "Name of the Key Vault."
  value       = azurerm_key_vault.keyvault.name
}
output "vault_uri" {
  description = "Data-plane URI of the Key Vault (https://<name>.vault.azure.net/)."
  value       = azurerm_key_vault.keyvault.vault_uri
}
output "resource_group_name" {
  description = "Name of the resource group containing the Key Vault."
  value       = azurerm_key_vault.keyvault.resource_group_name
}
output "tenant_id" {
  description = "Entra ID tenant ID the Key Vault is registered against."
  value       = azurerm_key_vault.keyvault.tenant_id
}
output "rbac_authorization_enabled" {
  description = "Whether the Key Vault uses Azure RBAC (true) or access policies (false) for data-plane authorization."
  value       = azurerm_key_vault.keyvault.rbac_authorization_enabled
}
output "private_endpoint_subresource_name" {
  description = "Sub-resource name to use when creating a private endpoint against this vault (the 'vault' subresource)."
  value       = "vault"
}
