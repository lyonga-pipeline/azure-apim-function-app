mock_provider "azurerm" {}
variables {
  peering_name              = "peer-hub-to-spoke"
  rg_name                   = "rg-hub"
  vnet_name                 = "vnet-hub"
  remote_virtual_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-spoke/providers/Microsoft.Network/virtualNetworks/vnet-spoke"
}
run "defaults" {
  command = apply
  assert {
    condition     = azurerm_virtual_network_peering.peering.allow_virtual_network_access == false
    error_message = "allow_virtual_network_access should default false"
  }
}
run "hub_gateway_transit" {
  command = apply
  variables {
    allow_gateway_transit        = true
    allow_virtual_network_access = true
  }
  assert {
    condition     = azurerm_virtual_network_peering.peering.allow_gateway_transit == true
    error_message = "allow_gateway_transit not wired"
  }
}
