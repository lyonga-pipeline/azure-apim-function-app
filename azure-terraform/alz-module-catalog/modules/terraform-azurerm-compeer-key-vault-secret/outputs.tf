output "ids" {
  description = "Map of caller-supplied key to Key Vault secret resource ID."
  value       = { for key, value in azurerm_key_vault_secret.this : key => value.id }
}
