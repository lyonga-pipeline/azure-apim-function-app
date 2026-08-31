mock_provider "azurerm" {}
variables {
  name                = "sb-platform"
  resource_group_name = "rg-msg"
  location            = "eastus2"
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_servicebus_namespace.main.name == "sb-platform"
    error_message = "name not wired"
  }
}
