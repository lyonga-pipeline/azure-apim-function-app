mock_provider "azurerm" {}
variables {
  local_network_gateways = {
    hq = {
      name                = "lng-hq"
      resource_group_name = "rg-connectivity"
      location            = "eastus2"
      gateway_address     = "203.0.113.1"
      address_space       = ["10.100.0.0/16"]
    }
  }
}
run "create" {
  command = apply
  assert {
    condition     = length(azurerm_local_network_gateway.this) == 1
    error_message = "expected one local network gateway"
  }
  assert {
    condition     = azurerm_local_network_gateway.this["hq"].name == "lng-hq"
    error_message = "name not wired from map value"
  }
}
run "add_gateway_is_additive" {
  command = apply
  variables {
    local_network_gateways = {
      hq     = { name = "lng-hq", resource_group_name = "rg", location = "eastus2", gateway_address = "203.0.113.1", address_space = ["10.100.0.0/16"] }
      branch = { name = "lng-branch", resource_group_name = "rg", location = "eastus2", gateway_address = "203.0.113.2", address_space = ["10.101.0.0/16"] }
    }
  }
  assert {
    condition     = length(azurerm_local_network_gateway.this) == 2
    error_message = "adding a key adds one gateway"
  }
}
