mock_provider "azurerm" {}
variables {
  name                       = "cn-hub-to-erc"
  resource_group_name        = "rg-connectivity"
  location                   = "eastus2"
  virtual_network_gateway_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworkGateways/ergw-hub"
  express_route_circuit_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/expressRouteCircuits/erc-primary"
}
run "expressroute_connection" {
  command = apply
  assert {
    condition     = azurerm_virtual_network_gateway_connection.connection.type == "ExpressRoute"
    error_message = "type default ExpressRoute"
  }
}
run "ipsec_requires_lng_and_key" {
  command = plan
  variables {
    type                     = "IPsec"
    express_route_circuit_id = null
  }
  expect_failures = [azurerm_virtual_network_gateway_connection.connection]
}

run "ipsec_requires_shared_key" {
  command = plan
  variables {
    type                     = "IPsec"
    express_route_circuit_id = null
    local_network_gateway_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/localNetworkGateways/onprem"
  }
  expect_failures = [azurerm_virtual_network_gateway_connection.connection]
}

run "rejects_bad_type" {
  command = plan
  variables {
    type = "Internet"
  }
  expect_failures = [var.type]
}

run "rejects_negative_routing_weight" {
  command = plan
  variables {
    routing_weight = -1
  }
  expect_failures = [var.routing_weight]
}
