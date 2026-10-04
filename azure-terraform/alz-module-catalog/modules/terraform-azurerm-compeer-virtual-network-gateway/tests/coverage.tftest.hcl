mock_provider "azurerm" {}

variables {
  name                = "platform-cus-prod-ergw"
  resource_group_name = "rg-connectivity"
  location            = "centralus"
  type                = "ExpressRoute"
  sku                 = "ErGw3AZ"
  ip_configurations = {
    default = {
      public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip-ergw"
      subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/platform-cus-prod-hub-vnet/subnets/GatewaySubnet"
    }
  }
}

# --- design doc shapes -------------------------------------------------------

run "design_doc_expressroute_gateway" {
  # platform-cus-prod-ergw: ExpressRoute, ErGw3AZ, GatewaySubnet.
  command = plan

  assert {
    condition     = azurerm_virtual_network_gateway.gateway.sku == "ErGw3AZ" && azurerm_virtual_network_gateway.gateway.type == "ExpressRoute"
    error_message = "the design-doc ExpressRoute gateway shape must be accepted"
  }
}

run "design_doc_active_active_vpn_gateway" {
  # platform-cus-prod-vpngw: Vpn, VpnGw4AZ, active-active, two public IPs, BGP.
  command = plan
  variables {
    name          = "platform-cus-prod-vpngw"
    type          = "Vpn"
    sku           = "VpnGw4AZ"
    active_active = true
    bgp_enabled   = true
    generation    = "Generation2"
    ip_configurations = {
      pip1 = {
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/platform-cus-prod-vpngw-pip1"
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/platform-cus-prod-hub-vnet/subnets/GatewaySubnet"
      }
      pip2 = {
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/platform-cus-prod-vpngw-pip2"
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/platform-cus-prod-hub-vnet/subnets/GatewaySubnet"
      }
    }
  }

  assert {
    condition     = azurerm_virtual_network_gateway.gateway.active_active == true && azurerm_virtual_network_gateway.gateway.sku == "VpnGw4AZ"
    error_message = "the design-doc active-active VPN gateway shape must be accepted"
  }
}

# --- outputs -----------------------------------------------------------------

run "outputs_are_wired" {
  command = apply

  assert {
    condition     = output.id == azurerm_virtual_network_gateway.gateway.id && output.name == azurerm_virtual_network_gateway.gateway.name
    error_message = "id/name outputs must echo the resource"
  }
}

# --- sku / type / generation -------------------------------------------------

run "rejects_unknown_sku" {
  command = plan
  variables {
    sku = "ErGw4AZ"
  }
  expect_failures = [var.sku]
}

run "rejects_vpn_sku_on_expressroute_gateway" {
  command = plan
  variables {
    sku = "VpnGw1"
  }
  expect_failures = [azurerm_virtual_network_gateway.gateway]
}

run "rejects_expressroute_sku_on_vpn_gateway" {
  command = plan
  variables {
    type = "Vpn"
    sku  = "ErGw3AZ"
  }
  expect_failures = [azurerm_virtual_network_gateway.gateway]
}

run "accepts_legacy_standard_sku_for_either_type" {
  command = plan
  variables {
    sku = "Standard"
  }

  assert {
    condition     = azurerm_virtual_network_gateway.gateway.sku == "Standard"
    error_message = "Standard exists for both gateway types and must be accepted"
  }
}

run "rejects_policy_based_vpn_on_non_basic_sku" {
  command = plan
  variables {
    type     = "Vpn"
    sku      = "VpnGw1"
    vpn_type = "PolicyBased"
  }
  expect_failures = [azurerm_virtual_network_gateway.gateway]
}

run "accepts_policy_based_vpn_on_basic_sku" {
  command = plan
  variables {
    type     = "Vpn"
    sku      = "Basic"
    vpn_type = "PolicyBased"
  }

  assert {
    condition     = azurerm_virtual_network_gateway.gateway.vpn_type == "PolicyBased"
    error_message = "PolicyBased is valid on the Basic SKU"
  }
}

run "rejects_bad_vpn_type" {
  command = plan
  variables {
    vpn_type = "HybridBased"
  }
  expect_failures = [var.vpn_type]
}

run "rejects_bad_generation" {
  command = plan
  variables {
    generation = "Generation3"
  }
  expect_failures = [var.generation]
}

run "accepts_valid_generation" {
  command = plan
  variables {
    type       = "Vpn"
    sku        = "VpnGw2AZ"
    generation = "Generation2"
  }

  assert {
    condition     = azurerm_virtual_network_gateway.gateway.generation == "Generation2"
    error_message = "a documented generation value should be accepted"
  }
}

run "rejects_empty_ip_configurations" {
  command = plan
  variables {
    ip_configurations = {}
  }
  expect_failures = [var.ip_configurations]
}

run "accepts_active_active_with_two_ip_configurations" {
  command = plan
  variables {
    type          = "Vpn"
    sku           = "VpnGw4AZ"
    active_active = true
    ip_configurations = {
      pip1 = {
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/platform-cus-prod-vpngw-pip1"
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/platform-cus-prod-hub-vnet/subnets/GatewaySubnet"
      }
      pip2 = {
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/platform-cus-prod-vpngw-pip2"
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/platform-cus-prod-hub-vnet/subnets/GatewaySubnet"
      }
    }
  }

  assert {
    condition     = length(azurerm_virtual_network_gateway.gateway.ip_configuration) == 2
    error_message = "two ip_configurations should satisfy active-active"
  }
}

# --- naming / required strings ----------------------------------------------

run "rejects_name_ending_with_hyphen" {
  command = plan
  variables {
    name = "platform-cus-prod-ergw-"
  }
  expect_failures = [var.name]
}

run "rejects_name_over_80_chars" {
  command = plan
  variables {
    name = join("", [for i in range(81) : "a"])
  }
  expect_failures = [var.name]
}

run "rejects_empty_resource_group_name" {
  command = plan
  variables {
    resource_group_name = ""
  }
  expect_failures = [var.resource_group_name]
}

run "rejects_blank_location" {
  command = plan
  variables {
    location = " "
  }
  expect_failures = [var.location]
}
