data "azurerm_client_config" "current" {}

data "azurerm_monitor_diagnostic_categories" "main" {
  resource_id = azurerm_api_management.apim.id
}