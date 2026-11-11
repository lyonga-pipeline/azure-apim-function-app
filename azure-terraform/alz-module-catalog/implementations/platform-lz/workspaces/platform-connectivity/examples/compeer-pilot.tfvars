location                  = "centralus"
environment               = "prod"
tfe_organization          = "Compeer-Financial-Services"
management_workspace_name = "platform-compeer-management"

platform_tags = {
  application         = "platform-connectivity"
  appcode             = "conn"
  owner               = "Cloud Enablement"
  source_repo         = "ado://Compeer-financial-cloud/Terraform/compeer-terraform-pflz-infrastructure"
  criticality_tier    = "tier-0"
  data_classification = "confidential"
  lifecycle_state     = "active"
  cost_center         = "CC-0000"
  gl_category         = "cloud-infrastructure"
  dr_tier             = "silver"
}

connectivity = {
  enabled        = true
  resource_group = {}
  hub_vnet = {
    address_space = ["10.102.0.0/21"]
    dns_servers   = ["10.102.8.20", "10.102.8.21"]
    subnets = {
      GatewaySubnet     = { address_prefixes = ["10.102.0.0/26"], route_table_key = "gateway" }
      RouteServerSubnet = { address_prefixes = ["10.102.0.64/26"] }

      prod-sdwan-lan-subnet = { address_prefixes = ["10.102.0.128/28"], route_table_key = "sdwan_lan" }
      prod-sdwan-wan-subnet = { address_prefixes = ["10.102.0.144/28"], route_table_key = "sdwan_wan" }

      prod-shared-subnet   = { address_prefixes = ["10.102.1.0/24"], route_table_key = "shared", nsg_key = "shared" }
      prod-appgw-subnet    = { address_prefixes = ["10.102.2.0/24"], route_table_key = "appgw", nsg_key = "appgw" }
      prod-cftagent-subnet = { address_prefixes = ["10.102.3.0/26"], route_table_key = "cftagent", nsg_key = "cftagent" }

      # PHASE 2: Dan confirmed management retains its existing table association.
      prod-mgmt-subnet = { address_prefixes = ["10.102.4.0/27"], route_table_key = "mgmt", nsg_key = "mgmt", service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"] }

      prod-fw-trust-subnet   = { address_prefixes = ["10.102.4.32/27"], route_table_key = "fw_trust", nsg_key = "fw_trust" }
      prod-fw-untrust-subnet = { address_prefixes = ["10.102.4.64/27"], route_table_key = "fw_untrust", nsg_key = "fw_untrust" }
      prod-fw-partner-subnet = { address_prefixes = ["10.102.4.96/27"], route_table_key = "fw_partner", nsg_key = "fw_partner" }
    }

  }
  ddos_protection_plan = {
    enabled             = false
    enable_for_hub_vnet = false
  }

  # names come from the naming module: <region>-<env>-<key>-nsg
  network_security_groups = {
    shared = {
      rules = {
        deny_sunstream     = { priority = 100, direction = "Inbound", access = "Deny", protocol = "*", source_address_prefix = "10.169.0.0/16", destination_address_prefix = "*", source_port_range = "*", destination_port_range = "*" }
        allow_all_internal = { priority = 200, direction = "Inbound", access = "Allow", protocol = "*", source_address_prefixes = ["10.0.0.0/8", "168.173.0.0/16"], destination_address_prefix = "*", source_port_range = "*", destination_port_range = "*" }
        allow_outbound     = { priority = 100, direction = "Outbound", access = "Allow", protocol = "*", source_address_prefix = "*", destination_address_prefix = "*", source_port_range = "*", destination_port_range = "*" }
      }
    }
    appgw = {
      rules = {
        deny_sunstream            = { priority = 100, direction = "Inbound", access = "Deny", protocol = "*", source_address_prefix = "10.169.0.0/16", destination_address_prefix = "*", source_port_range = "*", destination_port_range = "*" }
        allow_appgateway_v2_ports = { priority = 200, direction = "Inbound", access = "Allow", protocol = "Tcp", source_address_prefix = "*", destination_address_prefix = "*", source_port_range = "*", destination_port_range = "65200-65535" }
        cloudflare_appgateway     = { priority = 300, direction = "Inbound", access = "Allow", protocol = "Tcp", source_address_prefix = "10.102.3.0/26", destination_address_prefix = "VirtualNetwork", source_port_range = "*", destination_port_range = "443" }
      }
    }
    cftagent = {
      rules = {
        deny_sunstream = { priority = 100, direction = "Inbound", access = "Deny", protocol = "*", source_address_prefix = "10.169.0.0/16", destination_address_prefix = "*", source_port_range = "*", destination_port_range = "*" }
      }
    }
    mgmt = {
      rules = {
        deny_sunstream            = { priority = 100, direction = "Inbound", access = "Deny", protocol = "*", source_address_prefix = "10.169.0.0/16", destination_address_prefix = "*", source_port_range = "*", destination_port_range = "*" }
        allow_ping                = { priority = 200, direction = "Inbound", access = "Allow", protocol = "Icmp", source_address_prefix = "*", destination_address_prefix = "*", source_port_range = "*", destination_port_range = "*" }
        allow_internal_mgmt       = { priority = 300, direction = "Inbound", access = "Allow", protocol = "Tcp", source_address_prefixes = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"], destination_address_prefix = "*", source_port_range = "*", destination_port_ranges = ["22", "443"] }
        allow_solarwinds_inbound  = { priority = 400, direction = "Inbound", access = "Allow", protocol = "Tcp", source_address_prefix = "10.201.1.4", destination_address_prefix = "10.100.185.134", source_port_range = "*", destination_port_ranges = ["22", "443"] }
        allow_solarwinds_outbound = { priority = 220, direction = "Outbound", access = "Allow", protocol = "*", source_address_prefix = "10.100.185.134", destination_address_prefix = "10.201.1.4", source_port_range = "*", destination_port_range = "*" }
      }
    }
    fw_trust = {
      rules = {
        deny_sunstream     = { priority = 100, direction = "Inbound", access = "Deny", protocol = "*", source_address_prefix = "10.169.0.0/16", destination_address_prefix = "*", source_port_range = "*", destination_port_range = "*" }
        allow_ping         = { priority = 200, direction = "Inbound", access = "Allow", protocol = "Icmp", source_address_prefix = "*", destination_address_prefix = "*", source_port_range = "*", destination_port_range = "*" }
        allow_all_internal = { priority = 300, direction = "Inbound", access = "Allow", protocol = "*", source_address_prefixes = ["10.0.0.0/8", "168.173.0.0/16"], destination_address_prefix = "*", source_port_range = "*", destination_port_range = "*" }
        allow_health_check = { priority = 310, direction = "Inbound", access = "Allow", protocol = "Tcp", source_address_prefix = "168.63.129.16", destination_address_prefix = "10.102.4.32/27", source_port_range = "*", destination_port_range = "443" }
        allow_outbound     = { priority = 200, direction = "Outbound", access = "Allow", protocol = "*", source_address_prefix = "*", destination_address_prefix = "*", source_port_range = "*", destination_port_range = "*" }
      }
    }
    fw_untrust = {
      rules = {
        deny_sunstream = { priority = 100, direction = "Inbound", access = "Deny", protocol = "*", source_address_prefix = "10.169.0.0/16", destination_address_prefix = "*", source_port_range = "*", destination_port_range = "*" }
        allow_ping     = { priority = 200, direction = "Inbound", access = "Allow", protocol = "Icmp", source_address_prefix = "*", destination_address_prefix = "*", source_port_range = "*", destination_port_range = "*" }
        allow_outbound = { priority = 200, direction = "Outbound", access = "Allow", protocol = "*", source_address_prefix = "*", destination_address_prefix = "*", source_port_range = "*", destination_port_range = "*" }
      }
    }
    fw_partner = {
      rules = {
        allow_ping     = { priority = 200, direction = "Inbound", access = "Allow", protocol = "Icmp", source_address_prefix = "*", destination_address_prefix = "*", source_port_range = "*", destination_port_range = "*" }
        allow_outbound = { priority = 200, direction = "Outbound", access = "Allow", protocol = "*", source_address_prefix = "*", destination_address_prefix = "*", source_port_range = "*", destination_port_range = "*" }
      }
    }
  }
  subnet_nsg_associations = {} # derived from subnet.nsg_key above

  route_tables = {
    gateway = {
      bgp_route_propagation_enabled = true
      routes = {
        blackhole_fw_trust   = { name = "blackhole-fw-trust", address_prefix = "10.102.4.32/27", next_hop_type = "None" }
        blackhole_fw_untrust = { name = "blackhole-fw-untrust", address_prefix = "10.102.4.64/27", next_hop_type = "None" }
        blackhole_fw_partner = { name = "blackhole-fw-partner", address_prefix = "10.102.4.96/27", next_hop_type = "None" }
      }
    }
    sdwan_lan = {
      bgp_route_propagation_enabled = false
      routes                        = {}
    }
    sdwan_wan = {
      bgp_route_propagation_enabled = false
      routes                        = {}
    }
    shared = {
      bgp_route_propagation_enabled = false
      routes = {
        default              = { name = "default", address_prefix = "0.0.0.0/0", next_hop_type = "VirtualAppliance", next_hop_in_ip_address = "10.102.4.42" }
        blackhole_fw_trust   = { name = "blackhole-fw-trust", address_prefix = "10.102.4.32/27", next_hop_type = "None" }
        blackhole_fw_untrust = { name = "blackhole-fw-untrust", address_prefix = "10.102.4.64/27", next_hop_type = "None" }
        blackhole_fw_partner = { name = "blackhole-fw-partner", address_prefix = "10.102.4.96/27", next_hop_type = "None" }
      }
    }
    appgw = {
      bgp_route_propagation_enabled = false
      routes = {
        # Explicitly removed by firewall_routing.remove_route_keys during the approved cutover.
        default              = { name = "default", address_prefix = "0.0.0.0/0", next_hop_type = "VirtualAppliance", next_hop_in_ip_address = "10.102.4.42" }
        blackhole_fw_trust   = { name = "blackhole-fw-trust", address_prefix = "10.102.4.32/27", next_hop_type = "None" }
        blackhole_fw_untrust = { name = "blackhole-fw-untrust", address_prefix = "10.102.4.64/27", next_hop_type = "None" }
        blackhole_fw_partner = { name = "blackhole-fw-partner", address_prefix = "10.102.4.96/27", next_hop_type = "None" }
      }
    }
    cftagent = {
      bgp_route_propagation_enabled = false
      routes = {
        default              = { name = "default", address_prefix = "0.0.0.0/0", next_hop_type = "VirtualAppliance", next_hop_in_ip_address = "10.102.4.42" }
        blackhole_fw_trust   = { name = "blackhole-fw-trust", address_prefix = "10.102.4.32/27", next_hop_type = "None" }
        blackhole_fw_untrust = { name = "blackhole-fw-untrust", address_prefix = "10.102.4.64/27", next_hop_type = "None" }
        blackhole_fw_partner = { name = "blackhole-fw-partner", address_prefix = "10.102.4.96/27", next_hop_type = "None" }
      }
    }
    mgmt = {
      bgp_route_propagation_enabled = true
      routes = {
        default = { name = "default", address_prefix = "0.0.0.0/0", next_hop_type = "VirtualAppliance", next_hop_in_ip_address = "10.102.4.42" }
        # PHASE 2: explicit spoke destinations keep both directions through the
        # firewall. Extend this list for every additional approved deployed spoke.
        inspect_identity_internal = { address_prefix = "10.102.8.0/27", next_hop_type = "VirtualAppliance", next_hop_in_ip_address = "10.102.4.42" }
        inspect_pilot_application = { address_prefix = "10.102.64.0/27", next_hop_type = "VirtualAppliance", next_hop_in_ip_address = "10.102.4.42" }
      }
    }
    fw_trust = {
      bgp_route_propagation_enabled = true
      routes = {
        blackhole_internet   = { name = "blackhole-internet", address_prefix = "0.0.0.0/0", next_hop_type = "None" }
        blackhole_fw_untrust = { name = "blackhole-fw-untrust", address_prefix = "10.102.4.64/27", next_hop_type = "None" }
      }
    }
    fw_untrust = {
      bgp_route_propagation_enabled = false
      routes = {
        blackhole_hub = { name = "blackhole-hub", address_prefix = "10.102.0.0/21", next_hop_type = "None" }
      }
    }
    fw_partner = {
      bgp_route_propagation_enabled = true
      routes = {
        blackhole_internet   = { name = "blackhole-internet", address_prefix = "0.0.0.0/0", next_hop_type = "None" }
        blackhole_fw_untrust = { name = "blackhole-fw-untrust", address_prefix = "10.102.4.64/27", next_hop_type = "None" }
      }
    }
  }
  subnet_route_table_associations = {} # derived from subnet.route_table_key above  
}

firewall_routing = {
  enabled                    = true
  trust_ilb_frontend_ip      = "10.102.4.42"
  ownership_reviewed         = true
  firewall_path_ready        = true
  management_oob_confirmed   = true
  management_subnet_key      = "prod-mgmt-subnet"
  management_route_table_key = "mgmt" # Validate the base association above; does not create it.

  spoke_address_prefixes = {
    identity_internal = ["10.102.8.0/27"]
    pilot_application = ["10.102.64.0/27"]
    # identity_external = ["REPLACE_ONLY_IF_EXTERNAL_IDENTITY_IS_DEPLOYED"]
  }

  table_bindings = {
    gateway   = { route_table_key = "gateway", subnet_key = "GatewaySubnet" }
    sdwan_lan = { route_table_key = "sdwan_lan", subnet_key = "prod-sdwan-lan-subnet" }
    sdwan_wan = { route_table_key = "sdwan_wan", subnet_key = "prod-sdwan-wan-subnet" }
    shared    = { route_table_key = "shared", subnet_key = "prod-shared-subnet" }
    appgw     = { route_table_key = "appgw", subnet_key = "prod-appgw-subnet" }
    cftagent  = { route_table_key = "cftagent", subnet_key = "prod-cftagent-subnet" }
    fw_trust  = { route_table_key = "fw_trust", subnet_key = "prod-fw-trust-subnet" }
    # Untrust: every Hub VNet prefix -> None. BGP stays disabled.
    fw_untrust = { route_table_key = "fw_untrust", subnet_key = "prod-fw-untrust-subnet" }
    fw_partner = { route_table_key = "fw_partner", subnet_key = "prod-fw-partner-subnet" }
    # Management is configured in connectivity above, outside this generator.
  }

  # Remove legacy route workarounds that are not in the approved per-table matrix.
  remove_route_keys = {
    gateway  = ["blackhole_fw_trust", "blackhole_fw_partner"]
    shared   = ["blackhole_fw_trust"]
    appgw    = ["default", "blackhole_fw_trust"]
    cftagent = ["blackhole_fw_trust"]
  }
}
