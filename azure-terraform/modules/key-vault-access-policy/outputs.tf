output "ids" {
  value = { for key, value in azurerm_key_vault_access_policy.this : key => value.id }
}
