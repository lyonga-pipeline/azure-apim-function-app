mock_provider "azurerm" {}
mock_provider "time" {}
mock_provider "tfe" {}
variables {
  tenant_id       = "cccccccc-cccc-cccc-cccc-cccccccccccc"
  subscription_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
  use_tfe_outputs = false
  connectivity    = { enabled = false }
}
run "disabled_placeholders_are_non_deploying" {
  command = plan
  assert {
    condition     = !var.firewall_routing.enabled && length(module.connectivity) == 0 && length(terraform_data.firewall_routing_contract) == 0 && output.firewall_routing_review == null
    error_message = "The incomplete Hub cutover example must remain inert until real values and approvals are supplied."
  }
  assert {
    condition = (
      var.firewall_routing.trust_ilb_frontend_ip == "10.102.4.42" &&
      var.firewall_routing.spoke_address_prefixes.identity_internal == toset(["10.102.8.0/27"]) &&
      var.firewall_routing.spoke_address_prefixes.pilot_application == toset(["10.102.64.0/27"]) &&
      var.firewall_routing.table_bindings.gateway.name == "cus-prod-gateway-rt" &&
      var.firewall_routing.table_bindings.shared.name == "cus-prod-shared-rt" &&
      var.firewall_routing.table_bindings.appgw.name == "cus-prod-appgw-rt" &&
      var.firewall_routing.table_bindings.fw_trust.name == "cus-prod-fw-trust-rt" &&
      var.firewall_routing.table_bindings.fw_untrust.name == "cus-prod-fw-untrust-rt" &&
      var.firewall_routing.table_bindings.fw_partner.name == "cus-prod-fw-partner-rt"
    )
    error_message = "The Hub example must retain the documented frontend/names/Identity CIDR and the separately sourced pilot CIDR."
  }
  assert {
    condition     = !var.firewall_routing.ownership_reviewed && !var.firewall_routing.firewall_path_ready && !var.firewall_routing.management_oob_confirmed && var.firewall_routing.change_reference == ""
    error_message = "Optional audit metadata must default empty without asserting live readiness."
  }
}
