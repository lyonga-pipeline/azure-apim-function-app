# Defining Data Blocks

data "azurerm_client_config" "current" {}

## Azure Data Lake filesystem

resource "azurerm_storage_data_lake_gen2_filesystem" "data_lake_gen2_fs" {
  name               = var.data_lake_gen2_fs_name
  storage_account_id = var.storage_account_id
}