output "mssql_managed_instance_id" {
  description = "The Microsoft SQL Managed Instance ID."
  value       = azurerm_mssql_managed_instance.mssql_managed_instance.id
}

output "mssql_managed_instance_fqdn" {
  description = "The fully qualified domain name of the Azure Managed SQL Instance."
  value       = azurerm_mssql_managed_instance.mssql_managed_instance.fqdn
}

output "principal_id" {
  description = "MSSQL managed instance identity principal id"
  value = azurerm_mssql_managed_instance.mssql_managed_instance.identity.0.principal_id
}

output "tenant_id" {
  description = "MSSQL managed instance identity tenant id"
  value = azurerm_mssql_managed_instance.mssql_managed_instance.identity.0.tenant_id
}