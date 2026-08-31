# ============================================================================
# RESOURCE MODULE: Synapse workspace only. ADLS Gen2 filesystem, networking,
# private endpoints, diagnostics, and RBAC are externally owned and composed
# by the consuming pattern.
# ============================================================================

resource "azurerm_synapse_workspace" "synapse_workspace" {
  name                                 = var.synapse_workspace_name
  resource_group_name                  = var.resource_group_name
  location                             = var.location
  storage_data_lake_gen2_filesystem_id = var.storage_data_lake_gen2_filesystem_id
  sql_administrator_login              = var.sql_admin_login
  sql_administrator_login_password     = var.sql_admin_password
  managed_virtual_network_enabled      = var.managed_virtual_network_enabled
  public_network_access_enabled        = var.public_network_access_enabled
  data_exfiltration_protection_enabled = var.data_exfiltration_protection_enabled

  identity {
    type = var.synapse_workspace_identity
  }

  tags = var.tags
}

# aad_admin / sql_aad_admin are separate resources in azurerm >= 4.0. Managed
# only when an admin object is supplied so the workspace lifecycle stays
# independent of directory-admin churn.
resource "azurerm_synapse_workspace_aad_admin" "this" {
  count = var.aad_admin == null ? 0 : 1

  synapse_workspace_id = azurerm_synapse_workspace.synapse_workspace.id
  login                = var.aad_admin.login
  object_id            = var.aad_admin.object_id
  tenant_id            = var.aad_admin.tenant_id
}
