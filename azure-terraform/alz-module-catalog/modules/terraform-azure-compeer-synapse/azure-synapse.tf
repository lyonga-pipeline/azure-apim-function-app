resource "azurerm_storage_data_lake_gen2_filesystem" "data_lake_gen2_fs" {
  name               = var.data_lake_gen2_fs_name
  storage_account_id = data.azurerm_storage_account.storage_account.id
}

resource "azurerm_synapse_workspace" "synapse_workspace" {
  name                                 = var.synapse_workspace_name
  resource_group_name                  = var.resource_group_name
  location                             = var.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.data_lake_gen2_fs.id
  sql_administrator_login              = var.sql_admin_login
  sql_administrator_login_password     = var.sql_admin_password

  aad_admin {
    login     = var.aad_admin_login
    object_id = var.aad_admin_object_id
    tenant_id = var.aad_admin_tenant_id
  }

  identity {
    type = var.synapse_workspace_identity
  }

  tags = var.tags
}