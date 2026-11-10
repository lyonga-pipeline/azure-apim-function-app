# Real root and real child modules; providers mocked, no Azure/HCP calls.
mock_provider "azurerm" {
  mock_resource "azurerm_subnet" { defaults = { id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/platform-cus-prod-network-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/mock-subnet" } }
  mock_resource "azurerm_route_table" { defaults = { id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/platform-cus-prod-network-rg/providers/Microsoft.Network/routeTables/mock-rt" } }
}
mock_provider "time" {
  mock_resource "time_static" { defaults = { rfc3339 = "2026-11-09T00:00:00Z" } }
}
mock_provider "tfe" {}
variables {
  tenant_id       = "cccccccc-cccc-cccc-cccc-cccccccccccc"
  subscription_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
  use_tfe_outputs = false
  platform_tags = {
    application      = "alz-platform-connectivity", owner = "Network", source_repo = "ado://network",
    criticality_tier = "tier-0", data_classification = "confidential", lifecycle_state = "active",
    cost_center      = "CC-1", gl_category = "cloud-infrastructure", dr_tier = "silver"
  }
  connectivity = {
    enabled        = true
    platform_tags  = { appcode = "conn" }
    resource_group = { name = "platform-cus-prod-network-rg" }
    hub_vnet = {
      name          = "platform-cus-prod-hub-vnet"
      address_space = ["10.102.0.0/21"]
      subnets = {
        GatewaySubnet          = { address_prefixes = ["10.102.0.0/26"] }
        RouteServerSubnet      = { address_prefixes = ["10.102.0.64/26"] }
        prod-sdwan-lan-subnet  = { address_prefixes = ["10.102.0.128/28"], route_table_key = "sdwan_lan" }
        prod-sdwan-wan-subnet  = { address_prefixes = ["10.102.0.144/28"], route_table_key = "sdwan_wan" }
        prod-shared-subnet     = { address_prefixes = ["10.102.1.0/24"] }
        prod-appgw-subnet      = { address_prefixes = ["10.102.2.0/24"] }
        prod-cftagent-subnet   = { address_prefixes = ["10.102.3.0/26"], route_table_key = "to_firewall" }
        prod-mgmt-subnet       = { address_prefixes = ["10.102.4.0/27"] }
        prod-fw-trust-subnet   = { address_prefixes = ["10.102.4.32/27"] }
        prod-fw-untrust-subnet = { address_prefixes = ["10.102.4.64/27"] }
        prod-fw-partner-subnet = { address_prefixes = ["10.102.4.96/27"] }
      }
    }
    route_tables = {
      to_firewall = {
        name = "cus-prod-existing-cft-rt", bgp_route_propagation_enabled = true
        routes = {
          legacy-default   = { address_prefix = "0.0.0.0/0", next_hop_type = "VirtualAppliance", next_hop_in_ip_address = "10.102.0.132" }
          temporary-bypass = { address_prefix = "10.40.0.0/16", next_hop_type = "VirtualNetworkGateway" }
        }
      }
      sdwan_lan = { name = "cus-prod-sdwan-lan-rt", bgp_route_propagation_enabled = false, routes = {} }
      sdwan_wan = { name = "cus-prod-sdwan-wan-rt", bgp_route_propagation_enabled = false, routes = {} }
    }
    privatelink_zone_catalogue = []
  }
  firewall_routing = {
    enabled                = true, trust_ilb_frontend_ip = "10.102.4.42"
    change_reference       = "NET-123", ownership_reviewed = true, firewall_path_ready = true, management_oob_confirmed = true
    spoke_address_prefixes = { identity = ["10.102.8.0/27"], pilot = ["10.102.64.0/27"] }
    table_bindings = {
      gateway    = { route_table_key = "gateway", subnet_key = "GatewaySubnet", name = "cus-prod-gateway-rt" }
      sdwan_lan  = { route_table_key = "sdwan_lan", subnet_key = "prod-sdwan-lan-subnet" }
      sdwan_wan  = { route_table_key = "sdwan_wan", subnet_key = "prod-sdwan-wan-subnet" }
      shared     = { route_table_key = "shared", subnet_key = "prod-shared-subnet", name = "cus-prod-shared-rt" }
      appgw      = { route_table_key = "appgw", subnet_key = "prod-appgw-subnet", name = "cus-prod-appgw-rt" }
      cftagent   = { route_table_key = "to_firewall", subnet_key = "prod-cftagent-subnet" }
      fw_trust   = { route_table_key = "fw_trust", subnet_key = "prod-fw-trust-subnet", name = "cus-prod-fw-trust-rt" }
      fw_untrust = { route_table_key = "fw_untrust", subnet_key = "prod-fw-untrust-subnet", name = "cus-prod-fw-untrust-rt" }
      fw_partner = { route_table_key = "fw_partner", subnet_key = "prod-fw-partner-subnet", name = "cus-prod-fw-partner-rt" }
    }
    remove_route_keys = { to_firewall = ["temporary-bypass"] }
  }
}
run "disabled_is_exactly_backward_compatible" {
  command = plan
  variables { firewall_routing = {} }
  assert {
    condition = (
      length(terraform_data.firewall_routing_contract) == 0 && output.firewall_routing_review == null &&
      local.firewall_effective_route_tables == var.connectivity.route_tables &&
      local.firewall_effective_hub_vnet == var.connectivity.hub_vnet
    )
    error_message = "The default must not change routes, associations, BGP or names on deployed foundations."
  }
}
run "documented_matrix_preserves_table_and_route_identity" {
  command = plan
  assert {
    condition = (
      length(module.connectivity[0].route_table_ids) == 9 &&
      local.firewall_effective_route_tables.to_firewall.name == "cus-prod-existing-cft-rt" &&
      local.firewall_effective_route_tables.to_firewall.routes.legacy-default.next_hop_in_ip_address == "10.102.4.42" &&
      !contains(keys(local.firewall_effective_route_tables.to_firewall.routes), "temporary-bypass") &&
      !contains(keys(local.firewall_effective_route_tables.to_firewall.routes), "default") &&
      local.firewall_effective_route_tables.gateway.bgp_route_propagation_enabled &&
      local.firewall_effective_route_tables.fw_trust.bgp_route_propagation_enabled &&
      local.firewall_effective_route_tables.fw_partner.bgp_route_propagation_enabled
    )
    error_message = "Keep existing table keys/names and route names; replace only approved next hops, add document routes and remove only explicitly listed workarounds."
  }
  assert {
    condition = alltrue([for role in ["gateway", "sdwan_lan", "shared", "appgw", "cftagent"] :
      length([for route in values(local.firewall_desired_routes[role]) : route if contains(["10.102.8.0/27", "10.102.64.0/27"], route.address_prefix) && route.next_hop_type == "VirtualAppliance" && route.next_hop_in_ip_address == "10.102.4.42"]) == 2
      ]) && alltrue([for role in ["sdwan_wan", "fw_trust", "fw_untrust", "fw_partner"] :
      alltrue([for route in values(local.firewall_desired_routes[role]) : !contains(["10.102.8.0/27", "10.102.64.0/27"], route.address_prefix)])
    ])
    error_message = "Only the five inspection ingress tables receive every spoke prefix; firewall interfaces and WAN must not be blindly routed back to the Trust ILB."
  }
}
run "defaults_blackholes_and_subnet_bindings_match_document" {
  command = apply
  assert {
    condition = (
      alltrue([for role in ["gateway", "appgw"] : alltrue([for r in values(local.firewall_desired_routes[role]) : r.address_prefix != "0.0.0.0/0"])]) &&
      alltrue([for role in ["sdwan_lan", "shared", "cftagent"] : local.firewall_desired_routes[role].default.next_hop_type == "VirtualAppliance"]) &&
      local.firewall_desired_routes.fw_trust.drop-internet.next_hop_type == "None" &&
      local.firewall_desired_routes.fw_partner.drop-internet.address_prefix == "0.0.0.0/0" &&
      length(local.firewall_desired_routes.sdwan_wan) == 2 && length(local.firewall_desired_routes.fw_untrust) == 1 &&
      local.firewall_effective_hub_vnet.subnets["prod-fw-trust-subnet"].route_table_key == "fw_trust" &&
      try(local.firewall_effective_hub_vnet.subnets["prod-mgmt-subnet"].route_table_key, null) == null &&
      try(local.firewall_effective_hub_vnet.subnets.RouteServerSubnet.route_table_key, null) == null
    )
    error_message = "Do not add a default route to Gateway/App Gateway, disable Gateway BGP, or route management/Route Server through the firewall."
  }
}
run "every_documented_destination_and_no_extra_route_is_generated" {
  command = plan
  assert {
    condition = alltrue([for role, expected in {
      gateway    = { inspect = ["10.102.8.0/27", "10.102.64.0/27", "10.102.0.128/28", "10.102.1.0/24", "10.102.2.0/24", "10.102.3.0/26"], drop = ["10.102.4.64/27"] }
      sdwan_lan  = { inspect = ["10.102.8.0/27", "10.102.64.0/27", "10.102.1.0/24", "10.102.2.0/24", "10.102.3.0/26", "0.0.0.0/0"], drop = ["10.102.4.64/27"] }
      sdwan_wan  = { inspect = [], drop = ["10.102.4.64/27", "10.102.4.96/27"] }
      shared     = { inspect = ["10.102.8.0/27", "10.102.64.0/27", "10.102.0.128/28", "10.102.2.0/24", "10.102.3.0/26", "0.0.0.0/0"], drop = ["10.102.4.64/27", "10.102.4.96/27"] }
      appgw      = { inspect = ["10.102.8.0/27", "10.102.64.0/27", "10.102.0.128/28", "10.102.1.0/24", "10.102.3.0/26"], drop = ["10.102.4.64/27", "10.102.4.96/27"] }
      cftagent   = { inspect = ["10.102.8.0/27", "10.102.64.0/27", "10.102.0.128/28", "10.102.1.0/24", "10.102.2.0/24", "0.0.0.0/0"], drop = ["10.102.4.64/27", "10.102.4.96/27"] }
      fw_trust   = { inspect = [], drop = ["0.0.0.0/0", "10.102.4.64/27", "10.102.4.96/27"] }
      fw_untrust = { inspect = [], drop = ["10.102.0.0/21"] }
      fw_partner = { inspect = [], drop = ["0.0.0.0/0", "10.102.4.64/27", "10.102.4.32/27"] }
      } : (
      toset([for r in values(local.firewall_desired_routes[role]) : r.address_prefix if r.next_hop_type == "VirtualAppliance"]) == toset(expected.inspect) &&
      toset([for r in values(local.firewall_desired_routes[role]) : r.address_prefix if r.next_hop_type == "None"]) == toset(expected.drop) &&
      length(local.firewall_desired_routes[role]) == length(expected.inspect) + length(expected.drop)
    )])
    error_message = "Each table must match the document's exact inspection and blackhole destination set, not just a count or default route."
  }
}
run "additional_spokes_never_route_firewall_interfaces_to_their_own_ilb" {
  command = plan
  variables {
    firewall_routing = merge(var.firewall_routing, {
      spoke_address_prefixes = merge(var.firewall_routing.spoke_address_prefixes, { additional = ["10.102.96.0/24"] })
    })
  }
  assert {
    condition = alltrue([for role, prefixes in {
      fw_trust   = ["0.0.0.0/0", "10.102.4.64/27", "10.102.4.96/27"]
      fw_untrust = ["10.102.0.0/21"]
      fw_partner = ["0.0.0.0/0", "10.102.4.64/27", "10.102.4.32/27"]
      } : (
      toset([for r in values(local.firewall_effective_route_tables[var.firewall_routing.table_bindings[role].route_table_key].routes) : r.address_prefix]) == toset(prefixes) &&
      length(local.firewall_effective_route_tables[var.firewall_routing.table_bindings[role].route_table_key].routes) == length(prefixes) &&
      alltrue([for r in values(local.firewall_effective_route_tables[var.firewall_routing.table_bindings[role].route_table_key].routes) :
        r.next_hop_type == "None" && r.next_hop_in_ip_address == null
      ]) &&
      local.firewall_effective_hub_vnet.subnets[var.firewall_routing.table_bindings[role].subnet_key].route_table_key == var.firewall_routing.table_bindings[role].route_table_key
    )])
    error_message = "The effective firewall-interface tables/associations must contain only their exact blackholes, with no next-hop IP, regardless of the spoke inventory size."
  }
  assert {
    condition = (
      local.firewall_effective_route_tables.fw_trust.bgp_route_propagation_enabled &&
      !local.firewall_effective_route_tables.fw_untrust.bgp_route_propagation_enabled &&
      local.firewall_effective_route_tables.fw_partner.bgp_route_propagation_enabled &&
      try(local.firewall_effective_hub_vnet.subnets["prod-mgmt-subnet"].route_table_key, null) == null &&
      alltrue([for role in ["gateway", "sdwan_lan", "shared", "appgw", "cftagent"] :
        length([for r in values(local.firewall_desired_routes[role]) : r if r.address_prefix == "10.102.96.0/24" && r.next_hop_type == "VirtualAppliance"]) == 1
      ])
    )
    error_message = "Preserve per-interface BGP and OOB management; only the five documented ingress roles expand for an added spoke."
  }
}
run "explicit_association_key_is_preserved_without_duplicate" {
  command = plan
  variables { connectivity = merge(var.connectivity, {
    subnet_route_table_associations = { shared_existing_binding = { subnet_key = "prod-shared-subnet", route_table_key = "to_firewall" } }
  }) }
  assert {
    condition = (
      local.firewall_effective_associations.shared_existing_binding.route_table_key == "shared" &&
      local.firewall_effective_hub_vnet.subnets["prod-shared-subnet"].route_table_key == null
    )
    error_message = "Reuse an explicit association's Terraform key instead of creating a second association for its subnet."
  }
}
run "missing_cutover_approval_is_rejected" {
  command = plan
  variables { firewall_routing = merge(var.firewall_routing, { firewall_path_ready = false }) }
  expect_failures = [terraform_data.firewall_routing_contract]
}
run "audit_reference_can_be_omitted_without_changing_routes" {
  command = plan
  variables { firewall_routing = { for key, value in var.firewall_routing : key => value if key != "change_reference" } }
  assert {
    condition = (
      var.firewall_routing.change_reference == "" &&
      local.firewall_effective_route_tables.to_firewall.routes.legacy-default.next_hop_in_ip_address == "10.102.4.42" &&
      local.firewall_effective_route_tables.fw_trust.routes.drop-internet.next_hop_type == "None" &&
      length(local.firewall_effective_route_tables) == 9
    )
    error_message = "Optional audit metadata must not gate or change otherwise reviewed Hub routing."
  }
}
run "unselected_route_table_is_unchanged" {
  command = plan
  variables { connectivity = merge(var.connectivity, {
    route_tables = merge(var.connectivity.route_tables, { auxiliary = { name = "cus-prod-auxiliary-rt", bgp_route_propagation_enabled = true, routes = {} } })
  }) }
  assert {
    condition     = local.firewall_effective_route_tables.auxiliary == var.connectivity.route_tables.auxiliary
    error_message = "A routing cutover must not rewrite an unselected table."
  }
}
run "management_cannot_be_relabelled_as_gateway" {
  command = plan
  variables { firewall_routing = merge(var.firewall_routing, { management_subnet_key = "GatewaySubnet" }) }
  expect_failures = [terraform_data.firewall_routing_contract]
}
run "placeholder_next_hop_is_rejected" {
  command = plan
  variables { firewall_routing = merge(var.firewall_routing, { trust_ilb_frontend_ip = "REPLACE_WITH_DEPLOYED_IP" }) }
  expect_failures = [terraform_data.firewall_routing_contract]
}
run "next_hop_outside_trust_subnet_is_rejected" {
  command = plan
  variables { firewall_routing = merge(var.firewall_routing, { trust_ilb_frontend_ip = "10.102.4.72" }) }
  expect_failures = [terraform_data.firewall_routing_contract]
}
run "overlapping_spoke_and_hub_is_rejected" {
  command = plan
  variables { firewall_routing = merge(var.firewall_routing, { spoke_address_prefixes = { wrong = ["10.102.0.0/24"] } }) }
  expect_failures = [terraform_data.firewall_routing_contract]
}
run "renaming_existing_table_is_rejected" {
  command = plan
  variables { firewall_routing = merge(var.firewall_routing, {
    table_bindings = merge(var.firewall_routing.table_bindings, { cftagent = { route_table_key = "to_firewall", subnet_key = "prod-cftagent-subnet", name = "cus-prod-renamed-rt" } })
  }) }
  expect_failures = [terraform_data.firewall_routing_contract]
}
run "missing_role_is_rejected" {
  command = plan
  variables { firewall_routing = merge(var.firewall_routing, { table_bindings = { for k, v in var.firewall_routing.table_bindings : k => v if k != "appgw" } }) }
  expect_failures = [terraform_data.firewall_routing_contract]
}
run "existing_management_udr_requires_resolution" {
  command = plan
  variables { connectivity = merge(var.connectivity, { hub_vnet = merge(var.connectivity.hub_vnet, {
    subnets = merge(var.connectivity.hub_vnet.subnets, { prod-mgmt-subnet = { address_prefixes = ["10.102.4.0/27"], route_table_key = "to_firewall" } })
  }) }) }
  expect_failures = [terraform_data.firewall_routing_contract]
}
