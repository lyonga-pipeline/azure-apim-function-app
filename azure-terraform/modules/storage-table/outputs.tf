output "ids" { value = { for key, value in azurerm_storage_table.this : key => value.id } }
