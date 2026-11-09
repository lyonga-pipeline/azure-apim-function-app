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
}
