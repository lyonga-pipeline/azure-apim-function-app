output "ids" { value = { for key, value in azurerm_storage_blob.this : key => value.id } }
