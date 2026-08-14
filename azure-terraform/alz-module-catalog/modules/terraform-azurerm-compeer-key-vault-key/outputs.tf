output "ids" { value = { for key, value in azurerm_key_vault_key.this : key => value.id } }
