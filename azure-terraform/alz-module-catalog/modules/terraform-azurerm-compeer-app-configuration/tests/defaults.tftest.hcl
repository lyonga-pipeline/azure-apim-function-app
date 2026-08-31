mock_provider "azurerm" {}
variables {
  app_config_name     = "appcs-platform"
  resource_group_name = "rg-app"
  location            = "eastus2"
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_app_configuration.app_config.name == "appcs-platform"
    error_message = "name not wired"
  }
}
