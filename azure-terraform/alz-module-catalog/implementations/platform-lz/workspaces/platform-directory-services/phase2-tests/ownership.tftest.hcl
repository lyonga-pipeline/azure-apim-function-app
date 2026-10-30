# =============================================================================
# PHASE 2 CHANGES - additive, opt-in; preserve existing resource/state ownership.
# Copy this file together with the PHASE 2 section in main.tf and the example.
# =============================================================================
mock_provider "azurerm" {}
mock_provider "time" {}
mock_provider "tfe" {}
variables {
  tenant_id                        = "00000000-0000-0000-0000-000000000000"
  subscription_id                  = "11111111-1111-1111-1111-111111111111"
  use_tfe_outputs                  = false
  log_analytics_workspace_id       = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.OperationalInsights/workspaces/central-law"
  phase2_agent_ownership_confirmed = true

  directory_services = {
    enabled = true
    domain_controllers = { dc01 = {
      name                   = "platform-cus-prod-dc-01", nic_name = "platform-cus-prod-dc-01-nic"
      subnet_id              = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/identity-rg/providers/Microsoft.Network/virtualNetworks/identity-vnet/subnets/dc-subnet"
      private_ip_address     = "10.103.0.4"
      identity               = { type = "SystemAssigned, UserAssigned", identity_ids = ["/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/identity-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/ama-mi"] }
      source_image_reference = { publisher = "MicrosoftWindowsServer", offer = "WindowsServer", sku = "2022-datacenter-azure-edition", version = "20348.0000.000000" }
    } }
  }
  admin_passwords = { dc01 = "MockOnly!2026-Not-A-Real-Secret" }
}
run "existing_dc_owner_has_no_phase2_resources_by_default" {
  command = plan
  variables { phase2_agents = {} }
  assert {
    condition     = length(module.directory_services) == 1 && length(module.phase2_vm_observability) == 0
    error_message = "Existing DC ownership must be preserved with no implicit agent installation."
  }
}
run "dc_owner_resolves_vm_id_and_composes_ama" {
  command = plan
  assert {
    condition     = length(module.phase2_vm_observability[0].agent_ids) == 1 && length(module.phase2_vm_observability[0].endpoint_association_ids) == 1
    error_message = "DC telemetry must use VM IDs from this root and existing DCR/DCE inputs."
  }
}
run "unconfirmed_agent_ownership_is_rejected" {
  command = plan
  variables { phase2_agent_ownership_confirmed = false }
  expect_failures = [terraform_data.phase2_agent_contract]
}
run "agent_cannot_target_vm_outside_this_root" {
  command = plan
  variables {
    phase2_agents = { missing = {
      os_type               = "Windows", managed_identity_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/identity-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/ama-mi", identity_and_network_ready = true
      data_collection_rules = { baseline = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.Insights/dataCollectionRules/baseline" }
    } }
  }
  expect_failures = [terraform_data.phase2_agent_contract]
}
