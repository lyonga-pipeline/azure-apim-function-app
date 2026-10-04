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
    condition     = azurerm_virtual_network_gateway.gateway.type == "ExpressRoute"
    error_message = "type default"
  }
  assert {
    condition     = azurerm_virtual_network_gateway.gateway.bgp_enabled == true
    error_message = "BGP should default on for ExpressRoute gateways"
  }
}

run "bgp_enabled_preferred_over_deprecated_enable_bgp" {
  command = apply
  variables {
    bgp_enabled = false
    enable_bgp  = true
  }
  assert {
    condition     = azurerm_virtual_network_gateway.gateway.bgp_enabled == false
    error_message = "bgp_enabled should override deprecated enable_bgp"
  }
}

run "rejects_non_gateway_subnet" {
  command = plan
  variables {
    ip_configurations = {
      default = {
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip-ergw"
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/default"
      }
    }
  }
  expect_failures = [var.ip_configurations]
}

run "active_active_requires_two_ip_configurations" {
  command = plan
  variables {
    active_active = true
  }
  expect_failures = [azurerm_virtual_network_gateway.gateway]
}
