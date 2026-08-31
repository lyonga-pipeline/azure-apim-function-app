mock_provider "azurerm" {}
variables {
  name                = "ddos-platform"
  resource_group_name = "rg-connectivity"
  location            = "eastus2"
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_network_ddos_protection_plan.this.name == "ddos-platform"
    error_message = "name not wired"
  }
}
