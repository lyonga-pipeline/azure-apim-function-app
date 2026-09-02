output "synapse_workspace_id" {
  description = "Resource ID of the Synapse workspace."
  value       = azurerm_synapse_workspace.synapse_workspace.id
}
output "synapse_workspace_name" {
  description = "Name of the Synapse workspace."
  value       = azurerm_synapse_workspace.synapse_workspace.name
}
output "synapse_workspace_sql_admin_login" {
  description = "SQL administrator login name for the Synapse workspace."
  value       = azurerm_synapse_workspace.synapse_workspace.sql_administrator_login
}
output "storage_data_lake_gen2_filesystem_id" {
  description = "Resource ID of the ADLS Gen2 filesystem backing the workspace (passed through from input)."
  value       = var.storage_data_lake_gen2_filesystem_id
}

output "id" {
  description = "Resource ID of the Synapse workspace. Stable alias for synapse_workspace_id."
  value       = azurerm_synapse_workspace.synapse_workspace.id
}
output "name" {
  description = "Name of the Synapse workspace. Stable alias for synapse_workspace_name."
  value       = azurerm_synapse_workspace.synapse_workspace.name
}
