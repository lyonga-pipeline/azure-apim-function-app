mock_provider "azurerm" {}

variables {
  name                = "appi-orders"
  resource_group_name = "rg-app"
  location            = "eastus2"
  application_type    = "web"
}

run "create" {
  command = apply
  assert {
    condition     = azurerm_application_insights.application_insights.application_type == "web"
    error_message = "application_type not wired"
  }
}
