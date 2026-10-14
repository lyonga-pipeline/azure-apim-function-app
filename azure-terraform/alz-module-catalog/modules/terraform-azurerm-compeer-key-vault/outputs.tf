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

output "security_configuration" {
  description = "Observed non-secret security settings for composition contracts and integration assertions."
  value = {
    sku_name                        = azurerm_key_vault.keyvault.sku_name
    rbac_authorization_enabled      = azurerm_key_vault.keyvault.rbac_authorization_enabled
    public_network_access_enabled   = azurerm_key_vault.keyvault.public_network_access_enabled
    purge_protection_enabled        = azurerm_key_vault.keyvault.purge_protection_enabled
    soft_delete_retention_days      = azurerm_key_vault.keyvault.soft_delete_retention_days
    enabled_for_deployment          = azurerm_key_vault.keyvault.enabled_for_deployment
    enabled_for_disk_encryption     = azurerm_key_vault.keyvault.enabled_for_disk_encryption
    enabled_for_template_deployment = azurerm_key_vault.keyvault.enabled_for_template_deployment
    network_acl_bypass              = try(azurerm_key_vault.keyvault.network_acls[0].bypass, null)
    network_acl_default_action      = try(azurerm_key_vault.keyvault.network_acls[0].default_action, null)
  }
}
