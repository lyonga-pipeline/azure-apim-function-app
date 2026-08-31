mock_provider "azurerm" {}
variables {
  name                  = "erc-primary"
  resource_group_name   = "rg-connectivity"
  location              = "eastus2"
  service_provider_name = "Equinix"
  peering_location      = "Washington DC"
  bandwidth_in_mbps     = 200
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_express_route_circuit.this.bandwidth_in_mbps == 200
    error_message = "bandwidth not wired"
  }
}
