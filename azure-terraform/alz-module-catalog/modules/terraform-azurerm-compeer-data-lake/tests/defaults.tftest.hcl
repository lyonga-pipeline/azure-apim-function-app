mock_provider "azurerm" {}
variables {
  storage_account_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dl/providers/Microsoft.Storage/storageAccounts/stadls"
  data_lake_gen2_fs_name = "landing"
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_storage_data_lake_gen2_filesystem.data_lake_gen2_fs.name == "landing"
    error_message = "filesystem name not wired"
  }
}
