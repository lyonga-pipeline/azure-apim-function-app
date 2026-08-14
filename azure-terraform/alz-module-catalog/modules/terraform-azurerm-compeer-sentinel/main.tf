resource "azurerm_sentinel_log_analytics_workspace_onboarding" "this" {
  count = var.enabled ? 1 : 0

  workspace_id = var.log_analytics_workspace_id
}

resource "terraform_data" "data_connector_contract" {
  input = {
    sentinel_enabled = var.enabled
    connectors       = var.approved_data_connectors
  }
}
