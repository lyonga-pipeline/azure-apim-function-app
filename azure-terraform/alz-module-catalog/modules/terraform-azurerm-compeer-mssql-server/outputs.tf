output "mssql_server_id" {
  description = "The Microsoft SQL Server ID."
  value       = azurerm_mssql_server.mssql_server.id
}

output "mssql_server_fqdn" {
  description = "The fully qualified domain name of the Azure SQL Server (e.g. myServerName.database.windows.net)."
  value       = azurerm_mssql_server.mssql_server.fully_qualified_domain_name
}
output "id" {
  description = "The Microsoft SQL Server ID."
  value       = azurerm_mssql_server.mssql_server.id
}

output "name" {
  description = "The SQL Server name."
  value       = azurerm_mssql_server.mssql_server.name
}

output "fully_qualified_domain_name" {
  description = "The FQDN of the SQL Server."
  value       = azurerm_mssql_server.mssql_server.fully_qualified_domain_name
}

output "identity_principal_id" {
  description = "Principal ID of the system-assigned managed identity, when enabled."
  value       = try(azurerm_mssql_server.mssql_server.identity[0].principal_id, null)
}

output "identity_tenant_id" {
  description = "Tenant ID of the managed identity, when enabled."
  value       = try(azurerm_mssql_server.mssql_server.identity[0].tenant_id, null)
}
