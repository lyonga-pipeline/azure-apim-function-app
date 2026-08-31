mock_provider "azurerm" {}

variables {
  name                = "dce-platform"
  resource_group_name = "rg-mon"
  location            = "eastus2"
}

run "create" {
  command = apply
  assert {
    condition     = azurerm_monitor_data_collection_endpoint.this.name == "dce-platform"
    error_message = "name not wired"
  }
}
