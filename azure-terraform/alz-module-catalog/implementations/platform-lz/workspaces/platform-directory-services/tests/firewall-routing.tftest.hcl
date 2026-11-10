# Real Identity root/children with provider mocks; no live DC or network change.
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
  subscription_id = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
  use_tfe_outputs = false
  platform_tags = {
    application      = "alz-platform-directory-services", owner = "Identity", source_repo = "ado://identity",
    criticality_tier = "tier-0", data_classification = "confidential", lifecycle_state = "active",
    cost_center      = "CC-1", gl_category = "cloud-infrastructure", dr_tier = "silver"
  }
  directory_services = {
    enabled = true, platform_tags = { appcode = "ds" }
    identity_vnet = {
      name    = "identity-cus-prod-int-dc-vnet", address_space = ["10.102.8.0/27"]
      subnets = { prod-intdc-subnet = { address_prefixes = ["10.102.8.16/28"], route_table_key = "to_firewall" } }
    }
    route_tables = {
      to_firewall = {
        name = "cus-prod-intdc-rt", bgp_route_propagation_enabled = true
        routes = {
          temporary-egress = { address_prefix = "0.0.0.0/0", next_hop_type = "VirtualNetworkGateway" }
          temporary-direct = { address_prefix = "10.40.0.0/16", next_hop_type = "VirtualNetworkGateway" }
        }
      }
      untouched = { name = "cus-prod-other-rt", bgp_route_propagation_enabled = true, routes = {} }
    }
  }
  firewall_routing = {
    enabled                 = true, route_table_keys = ["to_firewall"], trust_ilb_frontend_ip = "10.102.4.42"
    hub_address_prefixes    = ["10.102.0.0/21"]
    remote_address_prefixes = { pilot = ["10.102.64.0/27"], onprem_test_fixture = ["168.173.0.0/16"] }
    remove_route_keys       = { to_firewall = ["temporary-direct"] }
    change_reference        = "NET-123", ownership_reviewed = true, firewall_path_ready = true, static_route_set_reviewed = true
  }
}
run "disabled_preserves_identity_routing" {
  command = plan
  variables { firewall_routing = {} }
  assert {
    condition = (
      output.firewall_routing_review == null && length(terraform_data.firewall_routing_contract) == 0 &&
      local.route_tables.to_firewall.bgp_route_propagation_enabled &&
      local.route_tables.to_firewall.routes == var.directory_services.route_tables.to_firewall.routes
    )
    error_message = "Do not change Identity's temporary BGP/static-route configuration until cutover is explicitly enabled."
  }
}
run "routes_and_bgp_change_together_without_renaming" {
  command = apply
  assert {
    condition = (
      local.route_tables.to_firewall.name == "cus-prod-intdc-rt" &&
      !local.route_tables.to_firewall.bgp_route_propagation_enabled &&
      local.route_tables.to_firewall.routes.temporary-egress.next_hop_type == "VirtualAppliance" &&
      local.route_tables.to_firewall.routes.temporary-egress.next_hop_in_ip_address == "10.102.4.42" &&
      !contains(keys(local.route_tables.to_firewall.routes), "temporary-direct") &&
      length(local.route_tables.to_firewall.routes) == 4 &&
      alltrue([for route in values(local.route_tables.to_firewall.routes) : route.next_hop_type == "VirtualAppliance" && route.next_hop_in_ip_address == "10.102.4.42"]) &&
      local.route_tables.untouched.bgp_route_propagation_enabled &&
      local.identity_vnet.address_space == var.directory_services.identity_vnet.address_space
    )
    error_message = "Preserve existing key/name, route name and VNet addresses; add default/hub/pilot/on-prem static routes, switch BGP off and leave unselected tables alone."
  }
}
run "unreviewed_static_set_is_rejected" {
  command = plan
  variables { firewall_routing = merge(var.firewall_routing, { static_route_set_reviewed = false }) }
  expect_failures = [terraform_data.firewall_routing_contract]
}
run "audit_reference_can_be_omitted_without_changing_routes" {
  command = plan
  variables { firewall_routing = { for key, value in var.firewall_routing : key => value if key != "change_reference" } }
  assert {
    condition = (
      var.firewall_routing.change_reference == "" &&
      length(local.route_tables.to_firewall.routes) == 4 &&
      !local.route_tables.to_firewall.bgp_route_propagation_enabled &&
      local.route_tables.to_firewall.name == "cus-prod-intdc-rt" &&
      local.route_tables.untouched.bgp_route_propagation_enabled
    )
    error_message = "Optional audit metadata must not gate or change an otherwise reviewed Identity cutover."
  }
}
run "pilot_only_remote_set_can_be_used_after_complete_review" {
  command = plan
  variables { firewall_routing = merge(var.firewall_routing, { remote_address_prefixes = { pilot = ["10.102.64.0/27"] } }) }
  assert {
    condition = (
      var.firewall_routing.static_route_set_reviewed &&
      toset([for route in values(local.route_tables.to_firewall.routes) : route.address_prefix]) == toset(["0.0.0.0/0", "10.102.0.0/21", "10.102.64.0/27"]) &&
      !local.route_tables.to_firewall.bgp_route_propagation_enabled
    )
    error_message = "No specifically named on-premises entry is mandatory when the complete approved set needs only hub/default/pilot routes."
  }
}
run "omitting_onprem_does_not_bypass_static_route_review" {
  command = plan
  variables { firewall_routing = merge(var.firewall_routing, {
    remote_address_prefixes = { pilot = ["10.102.64.0/27"] }, static_route_set_reviewed = false
  }) }
  expect_failures = [terraform_data.firewall_routing_contract]
}
run "empty_onprem_entry_is_rejected_instead_of_silently_ignored" {
  command = plan
  variables { firewall_routing = merge(var.firewall_routing, {
    remote_address_prefixes = { pilot = ["10.102.64.0/27"], onprem_domain_services = [] }
  }) }
  expect_failures = [terraform_data.firewall_routing_contract]
}
run "empty_table_selection_is_rejected_when_enabled" {
  command = plan
  variables { firewall_routing = merge(var.firewall_routing, { route_table_keys = [], remove_route_keys = {} }) }
  expect_failures = [terraform_data.firewall_routing_contract]
}
run "firewall_and_pilot_table_keys_cannot_be_selected_in_identity" {
  command = plan
  variables { firewall_routing = merge(var.firewall_routing, { route_table_keys = ["to_firewall", "fw_trust", "pilot_application"] }) }
  expect_failures = [terraform_data.firewall_routing_contract]
}
run "missing_remote_routes_are_rejected" {
  command = plan
  variables { firewall_routing = merge(var.firewall_routing, { remote_address_prefixes = {} }) }
  expect_failures = [terraform_data.firewall_routing_contract]
}
run "new_table_key_cannot_replace_deployed_identity_owner" {
  command = plan
  variables { firewall_routing = merge(var.firewall_routing, { route_table_keys = ["invented_new_table"], remove_route_keys = {} }) }
  expect_failures = [terraform_data.firewall_routing_contract]
}
run "placeholder_next_hop_is_rejected" {
  command = plan
  variables { firewall_routing = merge(var.firewall_routing, { trust_ilb_frontend_ip = "REPLACE_DEPLOYED_FRONTEND_IP" }) }
  expect_failures = [terraform_data.firewall_routing_contract]
}
run "unconfirmed_route_removal_is_rejected" {
  command = plan
  variables { firewall_routing = merge(var.firewall_routing, { remove_route_keys = { to_firewall = ["not-an-existing-route"] } }) }
  expect_failures = [terraform_data.firewall_routing_contract]
}
