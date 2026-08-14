output "data_lake_gen2_fs_id" {
  value       = azurerm_storage_data_lake_gen2_filesystem.data_lake_gen2_fs.id
  description = "The ID of the Data Lake Gen2 Filesystem."
}
output "data_lake_gen2_fs_name" {
  value       = azurerm_storage_data_lake_gen2_filesystem.data_lake_gen2_fs.name
  description = "The name of the Data Lake Gen2 Filesystem."
}
output "synapse_workspace_id" {
  value       = azurerm_synapse_workspace.synapse_workspace.id
  description = "The ID of the Synapse Workspace."
}
output "synapse_workspace_name" {
  value       = azurerm_synapse_workspace.synapse_workspace.name
  description = "The name of the Synapse Workspace."
}
output "synapse_workspace_sql_admin_login" {
  value       = azurerm_synapse_workspace.synapse_workspace.sql_administrator_login
  description = "The login name of the SQL administrator for the Synapse Workspace."
}