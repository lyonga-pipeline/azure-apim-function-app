mock_provider "azurerm" {}
variables {
  name                = "ergw-hub"
  resource_group_name = "rg-connectivity"
  location            = "eastus2"
  ip_configurations = {
    default = {
      public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip-ergw"
      subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/GatewaySubnet"
    }
  }
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_virtual_network_gateway.this.type == "ExpressRoute"
    error_message = "type default"
  }
}
