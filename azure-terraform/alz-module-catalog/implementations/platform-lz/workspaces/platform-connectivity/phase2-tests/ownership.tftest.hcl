# =============================================================================
# PHASE 2 CHANGES - additive, opt-in; preserve existing resource/state ownership.
# Copy this file together with the PHASE 2 section in main.tf and the example.
# =============================================================================
mock_provider "azurerm" {}
mock_provider "time" {}
mock_provider "tfe" {}
variables {
  tenant_id       = "00000000-0000-0000-0000-000000000000"
  subscription_id = "11111111-1111-1111-1111-111111111111"

  use_tfe_outputs = false
  connectivity = {
    enabled                    = true
    hub_vnet                   = { name = "platform-cus-prod-hub-vnet", address_space = ["10.102.0.0/21"], subnets = {} }
    privatelink_zone_catalogue = []
  }
}
run "network_monitoring_is_opt_in" {
  command = plan
  variables { phase2_connection_monitors = {} }
  assert {
    condition     = length(module.connectivity) == 1 && length(module.phase2_connection_monitors) == 0
    error_message = "No connection monitor should be added to Phase 1 by default."
  }
}
run "connectivity_owner_composes_pilot_monitor" {
  command = plan
  assert {
    condition     = length(module.phase2_connection_monitors[0].connection_monitor_ids) == 1 && length(module.phase2_connection_monitors[0].agent_ids) == 0
    error_message = "Network probes belong to connectivity; this extension does not deploy VM agents."
  }
}
run "probe_in_another_subscription_is_rejected" {
  command = plan
  variables { subscription_id = "22222222-2222-2222-2222-222222222222" }
  expect_failures = [terraform_data.phase2_connection_monitor_contract]
}
