resource "azurerm_resource_group" "rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_role_assignment" "logs" {
  count                = length(var.log_analytics_contributors)
  scope                = local.resource_group_id
  role_definition_name = var.log_analytics_role_definition_name
  principal_id         = var.log_analytics_contributors[count.index]
}

resource "azurerm_log_analytics_workspace" "logs" {
  name                = var.log_analytics_workspace_name
  location            = local.location
  resource_group_name = local.resource_group_name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_analytics_retention_in_days
  daily_quota_gb      = var.log_analytics_daily_quota_gb

  tags = var.tags
}

resource "azurerm_security_center_workspace" "logs" {
  count        = length(var.log_analytics_security_center_subscription)
  scope        = "/subscriptions/${element(var.log_analytics_security_center_subscription, count.index)}"
  workspace_id = azurerm_log_analytics_workspace.logs.id
}