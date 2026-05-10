output "ids" { value = { for key, value in azurerm_storage_queue.this : key => value.id } }
