data "azurerm_client_config" "current" {}

data "azurerm_monitor_diagnostic_categories" "main" {
  resource_id = azurerm_linux_web_app.linux_web_app.id
}