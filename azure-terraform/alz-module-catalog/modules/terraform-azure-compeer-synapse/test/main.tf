provider "azurerm" {
  features {}
}

module "synapse_workspace" {
  source = "../"

  resource_group_name    = "rgr-test"
  location               = "northcentralus"
  storage_account_name   = "cfsactstncussb1sa"
  synapse_workspace_name = "test-synapse-1"
  data_lake_gen2_fs_name = "test-gen2-fs-01"
  sql_admin_login        = var.sql_admin_login
  sql_admin_password     = var.sql_admin_password
  aad_admin_login        = ""
  aad_admin_object_id    = ""
  aad_admin_tenant_id    = ""

  synapse_workspace_identity   = "SystemAssigned"
  synapse_workspace_key_active = true
  tags = {
    env = "dev"
  }
}
