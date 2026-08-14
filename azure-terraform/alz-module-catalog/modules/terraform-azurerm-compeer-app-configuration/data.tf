data "azurerm_client_config" "current" {}

data "azurerm_app_configuration" "app_config" {
  count               = var.create_app_config ? 0 : 1
  name                = var.app_config_name
  resource_group_name = var.resource_group_name
}

data "azurerm_monitor_diagnostic_categories" "main" {
  resource_id = azurerm_app_configuration.app_config[0].id
}