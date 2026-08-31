mock_provider "azurerm" {}
variables {
  name                = "dnspr-hub"
  resource_group_name = "rg-connectivity"
  location            = "eastus2"
  virtual_network_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet-hub"
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_private_dns_resolver.this.name == "dnspr-hub"
    error_message = "name not wired"
  }
}
