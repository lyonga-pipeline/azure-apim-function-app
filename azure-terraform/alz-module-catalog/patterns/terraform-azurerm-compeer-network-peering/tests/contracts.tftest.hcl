mock_provider "azurerm" {
  alias = "hub"
  mock_data "azurerm_client_config" {
    defaults = { subscription_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", tenant_id = "cccccccc-cccc-cccc-cccc-cccccccccccc" }
  }
}
mock_provider "azurerm" {
  alias = "spoke"
  mock_data "azurerm_client_config" {
    defaults = { subscription_id = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", tenant_id = "cccccccc-cccc-cccc-cccc-cccccccccccc" }
  }
}
mock_provider "azurerm" {
  alias = "dns"
  mock_data "azurerm_client_config" {
    defaults = { subscription_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", tenant_id = "cccccccc-cccc-cccc-cccc-cccccccccccc" }
  }
}
mock_provider "tfe" {
  mock_data "tfe_outputs" {
    defaults = {
      nonsensitive_values = {
        hub_resource_group_name   = "rg-hub", hub_virtual_network_name = "vnet-hub"
        hub_virtual_network_id    = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-hub"
        spoke_resource_group_name = "rg-spoke", spoke_virtual_network_name = "vnet-spoke"
        spoke_virtual_network_id  = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/rg-spoke/providers/Microsoft.Network/virtualNetworks/vnet-spoke"
      }
      values = { hub_virtual_network_name = "DO_NOT_READ_SENSITIVE_VALUES", spoke_virtual_network_name = "DO_NOT_READ_SENSITIVE_VALUES" }
    }
  }
}

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

run "reads_only_public_upstream_outputs" {
  command = apply
  variables {
    use_tfe_outputs   = true
    tfe_organization  = "integration-fixture"
    private_dns_zones = {}
  }
  assert {
    condition = (
      output.peerings.hub_to_spoke.remote_virtual_network_id == "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/rg-spoke/providers/Microsoft.Network/virtualNetworks/vnet-spoke" &&
      output.peerings.spoke_to_hub.remote_virtual_network_id == "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-hub"
    )
    error_message = "The HCP adapter must only consume approved nonsensitive outputs, never .values fallback data."
  }
}

run "rejects_conflicting_names_and_ids" {
  command = plan
  variables {
    hub_resource_group_name    = "rg-hub"
    hub_virtual_network_name   = "wrong-hub-name"
    hub_virtual_network_id     = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-hub"
    spoke_resource_group_name  = "rg-spoke"
    spoke_virtual_network_name = "vnet-spoke"
    spoke_virtual_network_id   = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/rg-spoke/providers/Microsoft.Network/virtualNetworks/vnet-spoke"
    private_dns_zones          = {}
  }
  expect_failures = [terraform_data.resolved_input_validation]
}
