output "resource_id" {
  description = "Id of Log Analytics resource in Azure."
  value       = azurerm_log_analytics_workspace.logs.id
}

output "id" {
  description = "Id of Log Analytics resource in Azure."
  value       = azurerm_log_analytics_workspace.logs.id
}

output "name" {
  description = "Name of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.logs.name
}

output "workspace_id" {
  description = "Log Analytics Workspace id, this is just a guid."
  value       = azurerm_log_analytics_workspace.logs.workspace_id
}

output "resource_group_name" {
  description = "Resource group containing the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.logs.resource_group_name
}

output "location" {
  description = "Azure region of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.logs.location
}

output "identity_principal_id" {
  description = "System-assigned identity principal ID when enabled."
  value       = try(azurerm_log_analytics_workspace.logs.identity[0].principal_id, null)
}
