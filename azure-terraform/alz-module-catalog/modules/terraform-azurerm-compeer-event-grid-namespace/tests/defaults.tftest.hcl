mock_provider "azurerm" {}
variables {
  namespace_name      = "egns-platform"
  resource_group_name = "rg-events"
  location            = "eastus2"
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_eventgrid_namespace.main.name == "egns-platform"
    error_message = "namespace name not wired"
  }
}
