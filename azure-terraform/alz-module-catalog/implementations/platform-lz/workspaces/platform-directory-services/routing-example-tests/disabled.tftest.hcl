mock_provider "azurerm" {}
mock_provider "time" {}
mock_provider "tfe" {}
variables {
  tenant_id          = "cccccccc-cccc-cccc-cccc-cccccccccccc"
  subscription_id    = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
  use_tfe_outputs    = false
  directory_services = { enabled = false }
}
run "disabled_placeholders_cannot_cut_identity_bgp" {
  command = plan
  assert {
    condition     = !var.firewall_routing.enabled && length(module.directory_services) == 0 && length(terraform_data.firewall_routing_contract) == 0 && output.firewall_routing_review == null
    error_message = "The incomplete Identity example must not change BGP or resources before its existing table and replacement routes are reviewed."
  }
  assert {
    condition = (
      var.firewall_routing.trust_ilb_frontend_ip == "10.102.4.42" &&
      var.firewall_routing.hub_address_prefixes == toset(["10.102.0.0/21"]) &&
      var.firewall_routing.remote_address_prefixes.pilot_application == toset(["10.102.64.0/27"])
    )
    error_message = "The Identity example must retain the documented frontend/hub CIDR and the separately sourced pilot CIDR."
  }
  assert {
    condition = (
      !var.firewall_routing.ownership_reviewed && !var.firewall_routing.firewall_path_ready && !var.firewall_routing.static_route_set_reviewed &&
      var.firewall_routing.change_reference == "" &&
      var.firewall_routing.route_table_keys == toset(["to_firewall"]) &&
      !contains(keys(var.firewall_routing.remote_address_prefixes), "onprem_domain_services")
    )
    error_message = "Select this root's existing table key, omit unprovided on-premises networks and keep readiness unconfirmed."
  }
}
