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
