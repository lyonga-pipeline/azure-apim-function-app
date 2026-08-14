data "azurerm_monitor_diagnostic_categories" "main" {
  resource_id = azurerm_application_gateway.main.id
}