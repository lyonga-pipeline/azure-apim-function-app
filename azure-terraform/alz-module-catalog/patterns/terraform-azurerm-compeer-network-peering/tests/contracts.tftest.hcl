mock_provider "azurerm" {
  alias = "hub"
}
mock_provider "azurerm" {
  alias = "spoke"
}
mock_provider "tfe" {}

# Exercises terraform_data.resolved_input_validation - the precondition that
# stops a half-resolved hub/spoke peering (e.g. a stale or unreadable
# tfe_outputs source) from silently planning against null resource IDs. Had
# zero test coverage before this file. use_tfe_outputs = false throughout so
# these runs drive resolution purely from explicit variables, without needing
# to fake a real TFE workspace.

variables {
  use_tfe_outputs       = false
  hub_subscription_id   = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
  spoke_subscription_id = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
}

run "missing_all_inputs_fails_cleanly" {
  command         = plan
  expect_failures = [terraform_data.resolved_input_validation]
}

run "missing_one_input_still_fails" {
  command = plan
  variables {
    hub_resource_group_name    = "rg-hub"
    hub_virtual_network_name   = "vnet-hub"
    hub_virtual_network_id     = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-hub"
    spoke_resource_group_name  = "rg-spoke"
    spoke_virtual_network_name = "vnet-spoke"
    # spoke_virtual_network_id intentionally left null
    private_dns_zone_resource_group_name = "rg-hub"
  }
  expect_failures = [terraform_data.resolved_input_validation]
}

run "fully_resolved_inputs_pass" {
  command = plan
  variables {
    hub_resource_group_name              = "rg-hub"
    hub_virtual_network_name             = "vnet-hub"
    hub_virtual_network_id               = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-hub"
    spoke_resource_group_name            = "rg-spoke"
    spoke_virtual_network_name           = "vnet-spoke"
    spoke_virtual_network_id             = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/rg-spoke/providers/Microsoft.Network/virtualNetworks/vnet-spoke"
    private_dns_zone_resource_group_name = "rg-hub"
  }
  assert {
    condition     = terraform_data.resolved_input_validation.input.spoke_virtual_network_id != null
    error_message = "expected the resolved spoke VNet ID to be recorded"
  }
}
