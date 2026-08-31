mock_provider "azurerm" {}
variables {
  resource_group_name = "rg-data"
  data_factory_name   = "adf-platform"
  location            = "eastus2"
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_data_factory.main_data_factory.name == "adf-platform"
    error_message = "name not wired"
  }
}
