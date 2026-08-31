output "id" {
  description = "The Microsoft SQL Managed Instance ID."
  value       = azurerm_mssql_managed_instance.mssql_managed_instance.id
}

output "mssql_managed_instance_id" {
  description = "The Microsoft SQL Managed Instance ID. (Deprecated alias of `id`.)"
  value       = azurerm_mssql_managed_instance.mssql_managed_instance.id
}

output "name" {
  description = "The Managed Instance name."
  value       = azurerm_mssql_managed_instance.mssql_managed_instance.name
}

output "fqdn" {
  description = "The fully qualified domain name of the Managed Instance."
  value       = azurerm_mssql_managed_instance.mssql_managed_instance.fqdn
}

output "mssql_managed_instance_fqdn" {
  description = "The FQDN of the Managed Instance. (Deprecated alias of `fqdn`.)"
  value       = azurerm_mssql_managed_instance.mssql_managed_instance.fqdn
}

output "identity_principal_id" {
  description = "Principal ID of the system-assigned managed identity, when enabled."
  value       = try(azurerm_mssql_managed_instance.mssql_managed_instance.identity[0].principal_id, null)
}

output "identity_tenant_id" {
  description = "Tenant ID of the managed identity, when enabled."
  value       = try(azurerm_mssql_managed_instance.mssql_managed_instance.identity[0].tenant_id, null)
}

output "principal_id" {
  description = "Identity principal ID. (Deprecated alias of `identity_principal_id`.)"
  value       = try(azurerm_mssql_managed_instance.mssql_managed_instance.identity[0].principal_id, null)
}

output "tenant_id" {
  description = "Identity tenant ID. (Deprecated alias of `identity_tenant_id`.)"
  value       = try(azurerm_mssql_managed_instance.mssql_managed_instance.identity[0].tenant_id, null)
}
