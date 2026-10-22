output "ids" {
  description = "Map of caller-supplied key to Key Vault key resource ID."
  value       = { for key, value in azurerm_key_vault_key.key : key => value.id }
}

output "versionless_ids" {
  description = "Versionless key URIs keyed by caller-supplied key name."
  value       = { for key, value in azurerm_key_vault_key.key : key => value.versionless_id }
}
