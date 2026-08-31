output "id" { value = azurerm_key_vault.keyvault.id }
output "name" { value = azurerm_key_vault.keyvault.name }
output "vault_uri" { value = azurerm_key_vault.keyvault.vault_uri }
output "resource_group_name" { value = azurerm_key_vault.keyvault.resource_group_name }
output "tenant_id" { value = azurerm_key_vault.keyvault.tenant_id }
output "rbac_authorization_enabled" { value = azurerm_key_vault.keyvault.rbac_authorization_enabled }
output "private_endpoint_subresource_name" { value = "vault" }
