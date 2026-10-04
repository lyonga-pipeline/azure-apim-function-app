mock_provider "azurerm" {
  mock_resource "azurerm_route_server" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-connectivity/providers/Microsoft.Network/virtualHubs/rs-hub"
    }
  }
}

variables {
  route_servers = {
    hub = {
      name                 = "platform-cus-prod-rs"
      resource_group_name  = "platform-cus-prod-hybrid-rg"
      location             = "centralus"
      subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/platform-cus-prod-network-rg/providers/Microsoft.Network/virtualNetworks/platform-cus-prod-hub-vnet/subnets/RouteServerSubnet"
      public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/platform-cus-prod-hybrid-rg/providers/Microsoft.Network/publicIPAddresses/platform-cus-prod-rs-pip"
    }
  }
}

run "design_doc_route_server_shape" {
  # platform-cus-prod-rs: Standard, in the hybrid RG, RouteServerSubnet of the
  # hub VNet, platform-cus-prod-rs-pip.
  command = plan

  assert {
    condition     = azurerm_route_server.server["hub"].sku == "Standard" && azurerm_route_server.server["hub"].name == "platform-cus-prod-rs"
    error_message = "the design-doc route server shape must be accepted"
  }
}

run "outputs_are_wired" {
  command = apply
  variables {
    route_servers = {
      hub = {
        name                 = "platform-cus-prod-rs"
        resource_group_name  = "platform-cus-prod-hybrid-rg"
        location             = "centralus"
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/platform-cus-prod-network-rg/providers/Microsoft.Network/virtualNetworks/platform-cus-prod-hub-vnet/subnets/RouteServerSubnet"
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/platform-cus-prod-hybrid-rg/providers/Microsoft.Network/publicIPAddresses/platform-cus-prod-rs-pip"
        bgp_connections = {
          sdwan1 = { name = "sdwan-nva-1", peer_asn = 65010, peer_ip = "10.102.0.132" }
          sdwan2 = { name = "sdwan-nva-2", peer_asn = 65010, peer_ip = "10.102.0.133" }
        }
      }
    }
  }

  assert {
    condition = (
      output.ids["hub"] == azurerm_route_server.server["hub"].id &&
      output.names["hub"] == azurerm_route_server.server["hub"].name &&
      output.resource_group_names["hub"] == azurerm_route_server.server["hub"].resource_group_name &&
      output.route_servers["hub"].subnet_id == azurerm_route_server.server["hub"].subnet_id &&
      output.route_servers["hub"].branch_to_branch_traffic_enabled == azurerm_route_server.server["hub"].branch_to_branch_traffic_enabled
    )
    error_message = "route server outputs must echo the resource"
  }
  assert {
    condition     = length(output.bgp_connection_ids) == 2 && length(output.bgp_connections) == 2
    error_message = "each bgp_connections entry should produce its own connection and output entry"
  }
  assert {
    condition     = output.bgp_connections["hub-sdwan1"].peer_ip == "10.102.0.132" && output.bgp_connections["hub-sdwan2"].peer_ip == "10.102.0.133"
    error_message = "each BGP connection output must carry its OWN peer, keyed <route-server>-<connection>"
  }
}

run "branch_to_branch_can_be_disabled" {
  command = plan
  variables {
    route_servers = {
      hub = {
        name                             = "platform-cus-prod-rs"
        resource_group_name              = "platform-cus-prod-hybrid-rg"
        location                         = "centralus"
        subnet_id                        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/RouteServerSubnet"
        public_ip_address_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip"
        branch_to_branch_traffic_enabled = false
      }
    }
  }

  assert {
    condition     = azurerm_route_server.server["hub"].branch_to_branch_traffic_enabled == false
    error_message = "branch_to_branch_traffic_enabled = false must be honored (the design doc leaves this open pending CDW)"
  }
}

run "empty_route_servers_is_a_noop" {
  command = plan
  variables {
    route_servers = {}
  }

  assert {
    condition     = length(azurerm_route_server.server) == 0 && length(azurerm_route_server_bgp_connection.bgp_connection) == 0
    error_message = "an empty map must create nothing"
  }
}

run "rejects_unresolved_subnet" {
  # In the hybrid workspace the subnet is resolved from platform-connectivity's
  # published subnet_ids; if that is not published yet the value is null, and
  # this must fail loudly rather than build a Route Server with no subnet.
  command = plan
  variables {
    route_servers = {
      hub = {
        name                 = "platform-cus-prod-rs"
        resource_group_name  = "platform-cus-prod-hybrid-rg"
        location             = "centralus"
        subnet_id            = null
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip"
      }
    }
  }
  expect_failures = [var.route_servers]
}

run "rejects_unresolved_public_ip" {
  command = plan
  variables {
    route_servers = {
      hub = {
        name                 = "platform-cus-prod-rs"
        resource_group_name  = "platform-cus-prod-hybrid-rg"
        location             = "centralus"
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/RouteServerSubnet"
        public_ip_address_id = null
      }
    }
  }
  expect_failures = [var.route_servers]
}

run "rejects_non_standard_sku" {
  command = plan
  variables {
    route_servers = {
      hub = {
        name                 = "platform-cus-prod-rs"
        resource_group_name  = "platform-cus-prod-hybrid-rg"
        location             = "centralus"
        sku                  = "Basic"
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/RouteServerSubnet"
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip"
      }
    }
  }
  expect_failures = [var.route_servers]
}

run "rejects_two_route_servers_on_one_subnet" {
  command = plan
  variables {
    route_servers = {
      a = {
        name                 = "rs-a"
        resource_group_name  = "rg"
        location             = "centralus"
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/RouteServerSubnet"
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip-a"
      }
      b = {
        name                 = "rs-b"
        resource_group_name  = "rg"
        location             = "centralus"
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/RouteServerSubnet"
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip-b"
      }
    }
  }
  expect_failures = [var.route_servers]
}

run "accepts_two_route_servers_in_different_vnets" {
  command = plan
  variables {
    route_servers = {
      a = {
        name                 = "rs-a"
        resource_group_name  = "rg"
        location             = "centralus"
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet-a/subnets/RouteServerSubnet"
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip-a"
      }
      b = {
        name                 = "rs-b"
        resource_group_name  = "rg"
        location             = "eastus2"
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet-b/subnets/RouteServerSubnet"
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip-b"
      }
    }
  }

  assert {
    condition     = length(azurerm_route_server.server) == 2
    error_message = "route servers in different VNets must each be created"
  }
}

run "rejects_reserved_azure_private_asn" {
  command = plan
  variables {
    route_servers = {
      hub = {
        name                 = "platform-cus-prod-rs"
        resource_group_name  = "rg"
        location             = "centralus"
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/RouteServerSubnet"
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip"
        bgp_connections = {
          sdwan = { name = "sdwan", peer_asn = 65515, peer_ip = "10.102.0.132" } # the Route Server's own ASN
        }
      }
    }
  }
  expect_failures = [var.route_servers]
}

run "rejects_reserved_azure_public_asn" {
  command = plan
  variables {
    route_servers = {
      hub = {
        name                 = "platform-cus-prod-rs"
        resource_group_name  = "rg"
        location             = "centralus"
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/RouteServerSubnet"
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip"
        bgp_connections = {
          sdwan = { name = "sdwan", peer_asn = 12076, peer_ip = "10.102.0.132" } # ExpressRoute's public ASN
        }
      }
    }
  }
  expect_failures = [var.route_servers]
}

run "rejects_iana_reserved_documentation_asn" {
  command = plan
  variables {
    route_servers = {
      hub = {
        name                 = "platform-cus-prod-rs"
        resource_group_name  = "rg"
        location             = "centralus"
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/RouteServerSubnet"
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip"
        bgp_connections = {
          sdwan = { name = "sdwan", peer_asn = 64500, peer_ip = "10.102.0.132" }
        }
      }
    }
  }
  expect_failures = [var.route_servers]
}

run "rejects_four_byte_asn" {
  # Azure Route Server supports only 16-bit ASNs.
  command = plan
  variables {
    route_servers = {
      hub = {
        name                 = "platform-cus-prod-rs"
        resource_group_name  = "rg"
        location             = "centralus"
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/RouteServerSubnet"
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip"
        bgp_connections = {
          sdwan = { name = "sdwan", peer_asn = 4200000000, peer_ip = "10.102.0.132" }
        }
      }
    }
  }
  expect_failures = [var.route_servers]
}

run "accepts_private_asn_just_outside_the_reserved_range" {
  # 65516 is not in the Azure-reserved list (65515, 65517-65520).
  command = plan
  variables {
    route_servers = {
      hub = {
        name                 = "platform-cus-prod-rs"
        resource_group_name  = "rg"
        location             = "centralus"
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/RouteServerSubnet"
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip"
        bgp_connections = {
          sdwan = { name = "sdwan", peer_asn = 65516, peer_ip = "10.102.0.132" }
        }
      }
    }
  }

  assert {
    condition     = length(azurerm_route_server.server) == 1
    error_message = "a non-reserved private ASN must be accepted"
  }
}

run "rejects_more_than_16_bgp_peers" {
  command = plan
  variables {
    route_servers = {
      hub = {
        name                 = "platform-cus-prod-rs"
        resource_group_name  = "rg"
        location             = "centralus"
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/RouteServerSubnet"
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip"
        bgp_connections = { for i in range(17) : "peer${i}" => {
          name     = "peer-${i}"
          peer_asn = 65010
          peer_ip  = "10.102.0.${100 + i}"
        } }
      }
    }
  }
  expect_failures = [var.route_servers]
}

run "accepts_exactly_16_bgp_peers" {
  command = plan
  variables {
    route_servers = {
      hub = {
        name                 = "platform-cus-prod-rs"
        resource_group_name  = "rg"
        location             = "centralus"
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/RouteServerSubnet"
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip"
        bgp_connections = { for i in range(16) : "peer${i}" => {
          name     = "peer-${i}"
          peer_asn = 65010
          peer_ip  = "10.102.0.${100 + i}"
        } }
      }
    }
  }

  assert {
    condition     = length(azurerm_route_server_bgp_connection.bgp_connection) == 16
    error_message = "the documented 16-peer limit itself must be accepted"
  }
}
