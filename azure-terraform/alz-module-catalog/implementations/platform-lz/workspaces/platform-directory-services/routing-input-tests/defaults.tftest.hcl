mock_provider "azurerm" {}
mock_provider "time" {}
mock_provider "tfe" {}
variables {
  tenant_id       = "cccccccc-cccc-cccc-cccc-cccccccccccc"
  subscription_id = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
  use_tfe_outputs = false
}
run "deployable_identity_inputs_keep_bgp_off_and_no_other_spoke_inventory" {
  command = plan
  assert {
    condition = (
      !var.directory_services.route_tables.to_firewall.bgp_route_propagation_enabled &&
      var.directory_services.route_tables.to_firewall.routes.default.next_hop_in_ip_address == "10.102.4.42" &&
      length(var.firewall_routing.remote_address_prefixes) == 0
    )
    error_message = "The actual deployable Identity tfvars must keep BGP disabled, the firewall default, and no other-spoke inventory."
  }
}
