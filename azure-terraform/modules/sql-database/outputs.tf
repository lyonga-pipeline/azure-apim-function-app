output "ids" { value = { for key, value in azurerm_mssql_database.this : key => value.id } }
