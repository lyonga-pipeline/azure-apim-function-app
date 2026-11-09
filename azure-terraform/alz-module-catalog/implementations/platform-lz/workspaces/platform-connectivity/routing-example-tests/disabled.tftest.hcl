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
}
