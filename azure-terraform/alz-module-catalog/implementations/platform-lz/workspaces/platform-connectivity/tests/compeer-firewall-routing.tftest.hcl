# Reproduce the supplied existing-Hub plan with fake IDs and mocked providers.
mock_provider "azurerm" {
  mock_resource "azurerm_subnet" { defaults = { id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/platform-cus-prod-network-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/mock-subnet" } }
  mock_resource "azurerm_route_table" { defaults = { id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/platform-cus-prod-network-rg/providers/Microsoft.Network/routeTables/mock-rt" } }
}
mock_provider "time" {
  mock_resource "time_static" { defaults = { rfc3339 = "2026-11-10T00:00:00Z" } }
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
    enabled        = true, platform_tags = { appcode = "conn" }
    resource_group = { name = "platform-cus-prod-network-rg" }
    hub_vnet = {
      name = "platform-cus-prod-hub-vnet", address_space = ["10.102.0.0/21"]
      subnets = {
        GatewaySubnet          = { address_prefixes = ["10.102.0.0/26"], route_table_key = "gateway" }
        RouteServerSubnet      = { address_prefixes = ["10.102.0.64/26"] }
        prod-sdwan-lan-subnet  = { address_prefixes = ["10.102.0.128/28"], route_table_key = "sdwan_lan" }
        prod-sdwan-wan-subnet  = { address_prefixes = ["10.102.0.144/28"], route_table_key = "sdwan_wan" }
        prod-shared-subnet     = { address_prefixes = ["10.102.1.0/24"], route_table_key = "shared" }
        prod-appgw-subnet      = { address_prefixes = ["10.102.2.0/24"], route_table_key = "appgw" }
        prod-cftagent-subnet   = { address_prefixes = ["10.102.3.0/26"], route_table_key = "cftagent" }
        prod-mgmt-subnet       = { address_prefixes = ["10.102.4.0/27"], route_table_key = "mgmt" }
        prod-fw-trust-subnet   = { address_prefixes = ["10.102.4.32/27"], route_table_key = "fw_trust" }
        prod-fw-untrust-subnet = { address_prefixes = ["10.102.4.64/27"], route_table_key = "fw_untrust" }
        prod-fw-partner-subnet = { address_prefixes = ["10.102.4.96/27"], route_table_key = "fw_partner" }
      }
    }
    route_tables = {
      gateway = { bgp_route_propagation_enabled = true, routes = {
        blackhole_fw_untrust = { address_prefix = "10.102.4.64/27", next_hop_type = "None" }
      } }
      appgw = { bgp_route_propagation_enabled = false, routes = {
        default            = { address_prefix = "0.0.0.0/0", next_hop_type = "VirtualAppliance", next_hop_in_ip_address = "10.102.4.42" }
        blackhole_fw_trust = { address_prefix = "10.102.4.32/27", next_hop_type = "None" }
      } }
      cftagent = { bgp_route_propagation_enabled = false, routes = {
        default = { address_prefix = "0.0.0.0/0", next_hop_type = "VirtualAppliance", next_hop_in_ip_address = "10.102.4.42" }
      } }
      shared     = { bgp_route_propagation_enabled = false, routes = {} }
      sdwan_lan  = { bgp_route_propagation_enabled = false, routes = {} }
      sdwan_wan  = { bgp_route_propagation_enabled = false, routes = {} }
      fw_trust   = { bgp_route_propagation_enabled = true, routes = {} }
      fw_untrust = { bgp_route_propagation_enabled = false, routes = {} }
      fw_partner = { bgp_route_propagation_enabled = true, routes = {} }
      mgmt       = { bgp_route_propagation_enabled = true, routes = {} }
    }
    privatelink_zone_catalogue = []
  }
  firewall_routing = {
    enabled                    = true, trust_ilb_frontend_ip = "10.102.4.42"
    ownership_reviewed         = true, firewall_path_ready = true, management_oob_confirmed = true
    management_route_table_key = "mgmt"
    spoke_address_prefixes     = { identity = ["10.102.8.0/27"], pilot = ["10.102.64.0/27"] }
    table_bindings = {
      gateway    = { route_table_key = "gateway", subnet_key = "GatewaySubnet" }
      sdwan_lan  = { route_table_key = "sdwan_lan", subnet_key = "prod-sdwan-lan-subnet" }
      sdwan_wan  = { route_table_key = "sdwan_wan", subnet_key = "prod-sdwan-wan-subnet" }
      shared     = { route_table_key = "shared", subnet_key = "prod-shared-subnet" }
      appgw      = { route_table_key = "appgw", subnet_key = "prod-appgw-subnet" }
      cftagent   = { route_table_key = "cftagent", subnet_key = "prod-cftagent-subnet" }
      fw_trust   = { route_table_key = "fw_trust", subnet_key = "prod-fw-trust-subnet" }
      fw_untrust = { route_table_key = "fw_untrust", subnet_key = "prod-fw-untrust-subnet" }
      fw_partner = { route_table_key = "fw_partner", subnet_key = "prod-fw-partner-subnet" }
    }
    remove_route_keys = { appgw = ["default"] }
  }
}
run "supplied_plan_failures_are_reproduced_without_bypassing_guards" {
  command = plan
  variables { firewall_routing = merge(var.firewall_routing, {
    ownership_reviewed = false, firewall_path_ready = false, management_oob_confirmed = false
    remove_route_keys  = {}
    table_bindings = merge(var.firewall_routing.table_bindings, {
      gateway  = { route_table_key = "gateway", subnet_key = "GatewaySubnet", name = "cus-prod-gateway-rt" }
      cftagent = { route_table_key = "to_firewall", subnet_key = "prod-cftagent-subnet" }
    })
  }) }
  expect_failures = [terraform_data.firewall_routing_contract]
  assert {
    condition = (
      !local.firewall_readiness_checks.ownership_reviewed &&
      !local.firewall_binding_checks["gateway.table_name_preserved"] &&
      !local.firewall_route_checks["appgw.no_default_route"] &&
      length(local.firewall_effective_route_tables) == 11 &&
      local.firewall_effective_hub_vnet.subnets["prod-cftagent-subnet"].route_table_key == "to_firewall"
    )
    error_message = "Reproduce the readiness/name/default-route failures and accidental eleventh table from the supplied Compeer plan."
  }
}
run "corrected_bindings_reuse_all_ten_existing_tables" {
  command = apply
  assert {
    condition = (
      alltrue(values(local.firewall_binding_checks)) && alltrue(values(local.firewall_route_checks)) &&
      length(module.connectivity[0].route_table_ids) == 10 &&
      toset(keys(local.firewall_effective_route_tables)) == toset(keys(var.connectivity.route_tables)) &&
      !contains(keys(local.firewall_effective_route_tables), "to_firewall") &&
      local.firewall_effective_hub_vnet.subnets["prod-cftagent-subnet"].route_table_key == "cftagent" &&
      alltrue([for role, b in var.firewall_routing.table_bindings : local.firewall_effective_route_tables[b.route_table_key].name == null]) &&
      !contains(keys(local.firewall_effective_route_tables.appgw.routes), "default") &&
      local.firewall_effective_route_tables.mgmt == var.connectivity.route_tables.mgmt &&
      contains(keys(local.firewall_effective_route_tables.appgw.routes), "blackhole_fw_trust")
    )
    error_message = "Preserve generated names, existing cftagent binding and management table; remove only the explicitly approved App Gateway default."
  }
}
run "readiness_diagnostic_names_each_unconfirmed_flag" {
  command = plan
  variables { firewall_routing = merge(var.firewall_routing, {
    ownership_reviewed = false, firewall_path_ready = false, management_oob_confirmed = false
  }) }
  expect_failures = [terraform_data.firewall_routing_contract]
  assert {
    condition     = toset([for check, passed in local.firewall_readiness_checks : check if !passed]) == toset(["ownership_reviewed", "firewall_path_ready", "management_oob_confirmed"])
    error_message = "Readiness diagnostics must identify the actual false flags without requiring invented route changes."
  }
}
run "app_gateway_default_route_is_reported_specifically" {
  command = plan
  variables { firewall_routing = merge(var.firewall_routing, { remove_route_keys = {} }) }
  expect_failures = [terraform_data.firewall_routing_contract]
  assert {
    condition     = [for check, passed in local.firewall_route_checks : check if !passed] == ["appgw.no_default_route"]
    error_message = "A retained App Gateway default must not be misdiagnosed as a management or duplicate-route error."
  }
}
run "existing_management_association_is_not_silently_removed" {
  command = plan
  variables { connectivity = merge(var.connectivity, { hub_vnet = merge(var.connectivity.hub_vnet, {
    subnets = merge(var.connectivity.hub_vnet.subnets, { prod-mgmt-subnet = { address_prefixes = ["10.102.4.0/27"], route_table_key = "mgmt" } })
  }) }) }
  assert {
    condition     = alltrue(values(local.firewall_route_checks)) && local.firewall_effective_hub_vnet.subnets["prod-mgmt-subnet"].route_table_key == "mgmt"
    error_message = "Dan confirmed the existing management association must stay attached."
  }
}

run "missing_expected_management_association_is_rejected" {
  command = plan
  variables { connectivity = merge(var.connectivity, { hub_vnet = merge(var.connectivity.hub_vnet, {
    subnets = merge(var.connectivity.hub_vnet.subnets, { prod-mgmt-subnet = { address_prefixes = ["10.102.4.0/27"] } })
  }) }) }
  expect_failures = [terraform_data.firewall_routing_contract]
  assert {
    condition     = !local.firewall_route_checks["management.expected_association"]
    error_message = "A removed management association must fail the declared existing-table check."
  }
}

run "explicit_management_association_keeps_its_address" {
  command = plan
  variables { connectivity = merge(var.connectivity, {
    hub_vnet = merge(var.connectivity.hub_vnet, {
      subnets = merge(var.connectivity.hub_vnet.subnets, { prod-mgmt-subnet = { address_prefixes = ["10.102.4.0/27"] } })
    })
    subnet_route_table_associations = { original_management = { subnet_key = "prod-mgmt-subnet", route_table_key = "mgmt" } }
  }) }
  assert {
    condition     = alltrue(values(local.firewall_route_checks)) && local.firewall_effective_associations == var.connectivity.subnet_route_table_associations
    error_message = "Keep the explicit management association key and target unchanged."
  }
}

run "management_bgp_cannot_be_disabled_by_cutover_inputs" {
  command = plan
  variables { connectivity = merge(var.connectivity, {
    route_tables = merge(var.connectivity.route_tables, { mgmt = { bgp_route_propagation_enabled = false, routes = {} } })
  }) }
  expect_failures = [terraform_data.firewall_routing_contract]
}

run "duplicate_management_association_forms_are_rejected" {
  command = plan
  variables { connectivity = merge(var.connectivity, {
    subnet_route_table_associations = { duplicate_management = { subnet_key = "prod-mgmt-subnet", route_table_key = "mgmt" } }
  }) }
  expect_failures = [terraform_data.firewall_routing_contract]
}

run "management_routes_are_preserved_not_interpreted" {
  command = plan
  variables { connectivity = merge(var.connectivity, {
    route_tables = merge(var.connectivity.route_tables, { mgmt = { bgp_route_propagation_enabled = true, routes = {
      existing_default = { address_prefix = "0.0.0.0/0", next_hop_type = "VirtualAppliance", next_hop_in_ip_address = "10.102.4.42" }
    } } })
  }) }
  assert {
    condition     = local.firewall_effective_route_tables.mgmt == var.connectivity.route_tables.mgmt
    error_message = "Do not add or delete management routes while default-route intent is unresolved."
  }
}
