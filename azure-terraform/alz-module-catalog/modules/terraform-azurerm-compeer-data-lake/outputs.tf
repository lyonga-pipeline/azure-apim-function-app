output "data_lake_gen2_fs_id" {
  value       = azurerm_storage_data_lake_gen2_filesystem.data_lake_gen2_fs.id
  description = "The ID of the Data Lake Gen2 Filesystem."
}
output "id" {
  description = "Resource ID of the Data Lake Gen2 filesystem. Stable alias for data_lake_gen2_fs_id."
  value       = azurerm_storage_data_lake_gen2_filesystem.data_lake_gen2_fs.id
}
