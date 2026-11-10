mock_provider "azurerm" {}
mock_provider "time" {}
mock_provider "tfe" {}
variables {
  tenant_id       = "cccccccc-cccc-cccc-cccccccccccc"
  subscription_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
  use_tfe_outputs = false
  connectivity    = { enabled = false }
}
run "existing_hub_example_preserves_real_keys_without_enabling_cutover" {
  command = plan
  assert {
    condition = (
      !var.firewall_routing.enabled && !var.firewall_routing.ownership_reviewed &&
      !var.firewall_routing.firewall_path_ready && !var.firewall_routing.management_oob_confirmed &&
      length(terraform_data.firewall_routing_contract) == 0 && output.firewall_routing_review == null &&
      length(var.firewall_routing.table_bindings) == 9 &&
      var.firewall_routing.table_bindings.cftagent.route_table_key == "cftagent" &&
      alltrue([for b in values(var.firewall_routing.table_bindings) : b.name == null]) &&
      var.firewall_routing.remove_route_keys.appgw == toset(["default"])
    )
    error_message = "The existing-Compeer example must preserve table identities and explicitly review the App Gateway default removal without enabling deployment."
  }
}
