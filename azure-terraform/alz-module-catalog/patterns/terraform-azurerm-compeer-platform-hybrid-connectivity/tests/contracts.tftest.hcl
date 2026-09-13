mock_provider "azurerm" {}

# Exercises terraform_data.expressroute_contract and terraform_data.vpn_contract
# - the preconditions that stop hybrid connectivity from being "half-promoted"
# (a circuit/gateway with no approved provider design, BGP/routing sign-off, or
# cutover window). Had zero test coverage before this file.

variables {
  subscription_id = "00000000-0000-0000-0000-000000000000"
  location        = "centralus"
  environment     = "prod"
  resource_group  = { name = "rg-hybrid" }
}

run "expressroute_off_by_default_is_a_noop" {
  command = plan
  assert {
    condition     = terraform_data.expressroute_contract.input.enabled == false
    error_message = "ExpressRoute posture should be inert by default"
  }
}

run "expressroute_enabled_requires_resources" {
  command = plan
  variables {
    expressroute_posture = { enabled = true }
  }
  expect_failures = [terraform_data.expressroute_contract]
}

run "expressroute_enabled_requires_approvals" {
  command = plan
  variables {
    expressroute_posture = { enabled = true } # resources below satisfy the first precondition
    expressroute_circuits = {
      primary = { name = "er-primary", service_provider_name = "Equinix", peering_location = "Chicago", bandwidth_in_mbps = 200 }
    }
    gateway_public_ips = { gw = {} }
    expressroute_gateway = {
      ip_configurations = { primary = { public_ip_key = "gw", gateway_subnet_id = "/subscriptions/x/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/GatewaySubnet" } }
    }
    expressroute_connections = {
      primary = { name = "er-conn", circuit_key = "primary" }
    }
  }
  # provider_design_reference / bgp_and_routing_approved / cutover_window_approved all unset -> second precondition fails
  expect_failures = [terraform_data.expressroute_contract]
}

run "expressroute_fully_approved_passes" {
  command = plan
  variables {
    expressroute_posture = {
      enabled                   = true
      provider_design_reference = "ARCH-1234"
      bgp_and_routing_approved  = true
      cutover_window_approved   = true
    }
    expressroute_circuits = {
      primary = { name = "er-primary", service_provider_name = "Equinix", peering_location = "Chicago", bandwidth_in_mbps = 200 }
    }
    gateway_public_ips = { gw = {} }
    expressroute_gateway = {
      ip_configurations = { primary = { public_ip_key = "gw", gateway_subnet_id = "/subscriptions/x/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/GatewaySubnet" } }
    }
    expressroute_connections = {
      primary = { name = "er-conn", circuit_key = "primary" }
    }
  }
  assert {
    condition     = terraform_data.expressroute_contract.input.circuit_count == 1
    error_message = "expected the circuit count to be recorded"
  }
}

run "vpn_off_by_default_is_a_noop" {
  command = plan
  assert {
    condition     = terraform_data.vpn_contract.input.enabled == false
    error_message = "VPN posture should be inert by default"
  }
}

run "vpn_enabled_requires_resources" {
  command = plan
  variables {
    vpn_posture = { enabled = true }
  }
  expect_failures = [terraform_data.vpn_contract]
}

run "vpn_enabled_requires_approvals" {
  command = plan
  variables {
    vpn_posture            = { enabled = true }
    vpn_gateway_public_ips = { gw = {} }
    vpn_gateway = {
      ip_configurations = { primary = { public_ip_key = "gw", gateway_subnet_id = "/subscriptions/x/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/GatewaySubnet" } }
    }
    local_network_gateways = {
      onprem = { name = "lng-onprem", gateway_address = "203.0.113.10", address_space = ["10.10.0.0/16"] }
    }
    vpn_connections = {
      primary = { name = "vpn-conn", local_network_gateway_key = "onprem" }
    }
  }
  expect_failures = [terraform_data.vpn_contract]
}

run "vpn_fully_approved_passes" {
  command = plan
  variables {
    vpn_posture = {
      enabled                      = true
      design_reference             = "ARCH-5678"
      bgp_and_routing_approved     = true
      shared_key_handling_approved = true
      failover_test_approved       = true
    }
    vpn_gateway_public_ips = { gw = {} }
    vpn_gateway = {
      ip_configurations = { primary = { public_ip_key = "gw", gateway_subnet_id = "/subscriptions/x/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/GatewaySubnet" } }
    }
    local_network_gateways = {
      onprem = { name = "lng-onprem", gateway_address = "203.0.113.10", address_space = ["10.10.0.0/16"] }
    }
    vpn_connections = {
      primary = { name = "vpn-conn", local_network_gateway_key = "onprem" }
    }
  }
  assert {
    condition     = terraform_data.vpn_contract.input.local_network_gateway_count == 1
    error_message = "expected the local network gateway count to be recorded"
  }
}
