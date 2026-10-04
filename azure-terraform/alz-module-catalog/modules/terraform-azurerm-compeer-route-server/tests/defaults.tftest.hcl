mock_provider "azurerm" {
  # azurerm_route_server's id is a VirtualHub resource ID, and
  # azurerm_route_server_bgp_connection validates that format at plan time -
  # the default random mock string made every BGP-connection run fail.
  mock_resource "azurerm_route_server" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-connectivity/providers/Microsoft.Network/virtualHubs/rs-hub"
    }
  }
}
variables {
  route_servers = {
    hub = {
      name                 = "rs-hub"
      resource_group_name  = "rg-connectivity"
      location             = "eastus2"
      subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/RouteServerSubnet"
      public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip-rs"
    }
  }
}
run "create" {
  command = apply
  assert {
    condition     = length(azurerm_route_server.server) == 1
    error_message = "expected one route server"
  }
  assert {
    condition     = azurerm_route_server.server["hub"].branch_to_branch_traffic_enabled == true
    error_message = "branch-to-branch should default to true for SDWAN routing"
  }
}

run "creates_bgp_connection" {
  command = apply
  variables {
    route_servers = {
      hub = {
        name                 = "rs-hub"
        resource_group_name  = "rg-connectivity"
        location             = "eastus2"
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/RouteServerSubnet"
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip-rs"
        bgp_connections = {
          sdwan = {
            name     = "sdwan-nva"
            peer_asn = 65010
            peer_ip  = "10.102.0.132"
          }
        }
      }
    }
  }
  assert {
    condition     = length(azurerm_route_server_bgp_connection.bgp_connection) == 1
    error_message = "expected one BGP connection"
  }
}

run "rejects_non_route_server_subnet" {
  command = plan
  variables {
    route_servers = {
      hub = {
        name                 = "rs-hub"
        resource_group_name  = "rg-connectivity"
        location             = "eastus2"
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/shared-services"
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip-rs"
      }
    }
  }
  expect_failures = [var.route_servers]
}

run "rejects_invalid_bgp_peer" {
  command = plan
  variables {
    route_servers = {
      hub = {
        name                 = "rs-hub"
        resource_group_name  = "rg-connectivity"
        location             = "eastus2"
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/RouteServerSubnet"
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip-rs"
        bgp_connections = {
          sdwan = {
            name     = "sdwan-nva"
            peer_asn = 0
            peer_ip  = "not-an-ip"
          }
        }
      }
    }
  }
  expect_failures = [var.route_servers]
}
