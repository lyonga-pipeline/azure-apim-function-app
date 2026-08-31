mock_provider "azurerm" {}
variables {
  route_servers = {
    hub = {
      name                 = "rs-hub"
      resource_group_name  = "rg-connectivity"
      location             = "eastus2"
      subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/RouteServerSubnet"
      public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip-rs"
    }
  }
}
run "create" {
  command = apply
  assert {
    condition     = length(azurerm_route_server.this) == 1
    error_message = "expected one route server"
  }
}
