output "ids" { value = { for key, value in azurerm_key_vault_secret.this : key => value.id } }
