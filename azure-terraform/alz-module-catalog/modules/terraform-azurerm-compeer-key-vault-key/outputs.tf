output "ids" {
  description = "Map of caller-supplied key to Key Vault key resource ID."
  value       = { for key, value in azurerm_key_vault_key.this : key => value.id }
}
