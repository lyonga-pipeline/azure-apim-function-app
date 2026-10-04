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
    condition     = azurerm_express_route_circuit.circuit.bandwidth_in_mbps == 200
    error_message = "bandwidth not wired"
  }
  assert {
    condition     = azurerm_express_route_circuit.circuit.sku[0].tier == "Standard" && azurerm_express_route_circuit.circuit.sku[0].family == "MeteredData"
    error_message = "default SKU should be Standard/MeteredData"
  }
}

run "rejects_non_positive_bandwidth" {
  command = plan
  variables {
    bandwidth_in_mbps = 0
  }
  expect_failures = [var.bandwidth_in_mbps]
}

run "rejects_invalid_sku" {
  command = plan
  variables {
    sku = {
      tier   = "Developer"
      family = "MeteredData"
    }
  }
  expect_failures = [var.sku]
}
