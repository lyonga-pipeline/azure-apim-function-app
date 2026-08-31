# Defining Data Blocks

# Removed unused data lookup azurerm_client_config.current; dependencies are supplied explicitly.


## Azure Data Lake filesystem

resource "azurerm_storage_data_lake_gen2_filesystem" "data_lake_gen2_fs" {
  name               = var.data_lake_gen2_fs_name
  storage_account_id = var.storage_account_id
}