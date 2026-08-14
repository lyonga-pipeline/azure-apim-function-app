output "ids" { value = { for key, value in azurerm_key_vault_certificate.this : key => value.id } }
