mock_provider "azurerm" {}
variables {
  name                = "rt-spoke"
  resource_group_name = "rg-net"
  location            = "eastus2"
  routes = {
    default = { address_prefix = "0.0.0.0/0", next_hop_type = "VirtualAppliance", next_hop_in_ip_address = "10.0.0.4" }
  }
}
run "create" {
  command = apply
  assert {
    condition     = length(azurerm_route_table.this.route) == 1
    error_message = "expected one route"
  }
}
run "rejects_appliance_without_ip" {
  command = plan
  variables { routes = { x = { address_prefix = "0.0.0.0/0", next_hop_type = "VirtualAppliance" } } }
  expect_failures = [var.routes]
}
