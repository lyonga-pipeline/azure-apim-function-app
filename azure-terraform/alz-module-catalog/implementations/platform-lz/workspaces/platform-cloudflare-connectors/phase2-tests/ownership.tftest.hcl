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

  cloudflare_connectors = {
    enabled = true
    connectors = { connector01 = {
      name           = "platform-cus-prod-cf-01", nic_name = "platform-cus-prod-cf-01-nic"
      subnet_id      = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/hub-vnet/subnets/connectors-subnet"
      admin_ssh_keys = [{ username = "azureadmin", public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMVtK2PbtU3/7PtGpwrVJPa4KM0wMoZBLEJuu49CTkh test@example.com" }]
      identity       = { type = "SystemAssigned, UserAssigned", identity_ids = ["/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/identity-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/ama-mi"] }
    } }
  }
}
run "existing_connector_owner_has_no_phase2_resources_by_default" {
  command = plan
  variables { phase2_agents = {} }
  assert {
    condition     = length(module.cloudflare_connectors) == 1 && length(module.phase2_vm_observability) == 0
    error_message = "Connector baseline must remain unchanged unless agent configuration is explicit."
  }
}
run "connector_owner_composes_linux_ama" {
  command = plan
  assert {
    condition     = length(module.phase2_vm_observability[0].agent_ids) == 1 && length(module.phase2_vm_observability[0].endpoint_association_ids) == 1
    error_message = "Linux AMA must be composed with this root's connector VM IDs."
  }
}
run "unconfirmed_agent_ownership_is_rejected" {
  command = plan
  variables { phase2_agent_ownership_confirmed = false }
  expect_failures = [terraform_data.phase2_agent_contract]
}
run "reusing_existing_ama_does_not_create_an_extension" {
  command = plan
  variables {
    phase2_agents = { connector01 = {
      os_type               = "Linux", managed_identity_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/identity-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/ama-mi", identity_and_network_ready = true
      install_agent         = false, existing_agent_confirmed = true
      data_collection_rules = { baseline = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.Insights/dataCollectionRules/linux-syslog" }
    } }
  }
  assert {
    condition     = length(module.phase2_vm_observability[0].agent_ids) == 0 && length(module.phase2_vm_observability[0].association_ids) == 1
    error_message = "AMA reuse must not create a second extension owner."
  }
}
