output "id" {
  description = "Resource ID of the Key Vault managed storage account object."
  value       = azurerm_key_vault_managed_storage_account.this.id
}

output "name" {
  description = "Name of the Key Vault managed storage account object."
  value       = azurerm_key_vault_managed_storage_account.this.name
}

output "sas_token_definition_secret_ids" {
  description = "Key Vault secret IDs of the generated SAS token definitions, keyed by definition name."
  value       = { for k, v in azurerm_key_vault_managed_storage_account_sas_token_definition.this : k => v.secret_id }
}
