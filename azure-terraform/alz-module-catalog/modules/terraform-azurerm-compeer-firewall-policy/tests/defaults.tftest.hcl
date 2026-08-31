mock_provider "azurerm" {}
variables {
  name                = "afwp-hub"
  resource_group_name = "rg-connectivity"
  location            = "eastus2"
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_firewall_policy.this.name == "afwp-hub"
    error_message = "name not wired"
  }
}
