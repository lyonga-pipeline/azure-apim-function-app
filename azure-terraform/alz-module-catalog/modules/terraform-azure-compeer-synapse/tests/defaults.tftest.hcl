mock_provider "azurerm" {}
variables {
  synapse_workspace_name               = "syn-platform"
  resource_group_name                  = "rg-analytics"
  location                             = "eastus2"
  storage_data_lake_gen2_filesystem_id = "https://stadls.dfs.core.windows.net/fs01"
  sql_admin_login                      = "sqladminuser"
  sql_admin_password                   = "P@ssw0rd-Synapse-1234"
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_synapse_workspace.synapse_workspace.name == "syn-platform"
    error_message = "workspace name not wired"
  }
}
run "no_aad_admin_by_default" {
  command = plan
  assert {
    condition     = length(azurerm_synapse_workspace_aad_admin.this) == 0
    error_message = "aad admin should not be managed when aad_admin is null"
  }
}
