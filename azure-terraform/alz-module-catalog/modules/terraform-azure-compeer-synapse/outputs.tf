output "synapse_workspace_id" { value = azurerm_synapse_workspace.synapse_workspace.id }
output "synapse_workspace_name" { value = azurerm_synapse_workspace.synapse_workspace.name }
output "synapse_workspace_sql_admin_login" { value = azurerm_synapse_workspace.synapse_workspace.sql_administrator_login }
output "storage_data_lake_gen2_filesystem_id" { value = var.storage_data_lake_gen2_filesystem_id }
