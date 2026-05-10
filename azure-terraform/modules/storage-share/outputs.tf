output "ids" { value = { for key, value in azurerm_storage_share.this : key => value.id } }
