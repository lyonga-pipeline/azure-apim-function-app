mock_provider "azurerm" {}
variables {
  name                = "afw-hub"
  resource_group_name = "rg-connectivity"
  location            = "eastus2"
  ip_configurations = {
    primary = {
      subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/AzureFirewallSubnet"
      public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip-afw"
    }
  }
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_firewall.this.name == "afw-hub"
    error_message = "name not wired"
  }
}
