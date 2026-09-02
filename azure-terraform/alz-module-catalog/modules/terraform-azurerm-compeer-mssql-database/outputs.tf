output "mssql_database_id" {
  description = "The Microsoft SQL Database ID."
  value       = azurerm_mssql_database.mssql_database.id
}

output "id" {
  description = "Resource ID of the SQL database. Stable alias for mssql_database_id."
  value       = azurerm_mssql_database.mssql_database.id
}
output "name" {
  description = "Name of the SQL database."
  value       = azurerm_mssql_database.mssql_database.name
}
