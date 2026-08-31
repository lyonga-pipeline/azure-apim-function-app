mock_provider "azurerm" {}

variables {
  name                = "rt-spoke-test"
  location            = "eastus2"
  resource_group_name = "rg-net-test"

  routes = {
    to-firewall = {
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "10.0.0.4"
    }
    to-hub = {
      address_prefix = "10.0.0.0/16"
      next_hop_type  = "VnetLocal"
    }
  }
}

run "create" {
  command = plan

  assert {
    condition     = length(azurerm_route_table.rt.route) == 2
    error_message = "Expected two routes"
  }
  assert {
    condition     = azurerm_route_table.rt.bgp_route_propagation_enabled == true
    error_message = "bgp_route_propagation_enabled should default true"
  }
}

run "add_route_is_additive" {
  command = plan

  variables {
    routes = {
      to-firewall = { address_prefix = "0.0.0.0/0", next_hop_type = "VirtualAppliance", next_hop_in_ip_address = "10.0.0.4" }
      to-hub      = { address_prefix = "10.0.0.0/16", next_hop_type = "VnetLocal" }
      to-onprem   = { address_prefix = "192.168.0.0/16", next_hop_type = "VirtualNetworkGateway" }
    }
  }

  assert {
    condition     = length(azurerm_route_table.rt.route) == 3
    error_message = "Adding a route key adds one route"
  }
}

run "rejects_appliance_without_ip" {
  command = plan

  variables {
    routes = { bad = { address_prefix = "0.0.0.0/0", next_hop_type = "VirtualAppliance" } }
  }

  expect_failures = [var.routes]
}
