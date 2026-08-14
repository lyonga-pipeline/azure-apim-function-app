output "mssql_server_id" {
  description = "The Microsoft SQL Server ID."
  value       = azurerm_mssql_server.mssql_server.id
}

output "mssql_server_fqdn" {
  description = "The fully qualified domain name of the Azure SQL Server (e.g. myServerName.database.windows.net)."
  value       = azurerm_mssql_server.mssql_server.fully_qualified_domain_name
}