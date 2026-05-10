output "ids" { value = { for key, value in azurerm_storage_container.this : key => value.id } }
