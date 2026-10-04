mock_provider "azurerm" {}

# Exercises terraform_data.expressroute_contract
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

run "route_server_creates_public_ip_and_server" {
  command = plan
  variables {
    route_server_public_ips = {
      primary = {
        name  = "pip-route-server"
        zones = ["1", "2", "3"]
      }
    }
    route_servers = {
      primary = {
        name                             = "rs-hub"
        subnet_id                        = "/subscriptions/x/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/RouteServerSubnet"
        public_ip_key                    = "primary"
        branch_to_branch_traffic_enabled = true
      }
    }
  }
  assert {
    condition     = length(module.route_server_public_ips) == 1
    error_message = "expected the route-server public IP to be created"
  }
  assert {
    condition     = length(module.route_servers.ids) == 1
    error_message = "expected the route server to be created"
  }
}
