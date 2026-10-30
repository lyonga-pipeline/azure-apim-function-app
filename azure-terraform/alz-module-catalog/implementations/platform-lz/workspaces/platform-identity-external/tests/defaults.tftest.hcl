mock_provider "azurerm" {}
variables { existing_identity_owner_checked = true } # Mock-only ownership fixture; example remains unapproved.

run "synthetic_example_is_disabled" {
  command = plan
  assert {
    condition     = length(module.external_identity) == 0
    error_message = "Synthetic values must not deploy a landing zone."
  }
}
run "approved_two_dc_infrastructure_composes" {
  command = plan
  variables {
    enabled             = true
    deployment_approved = true
    admin_passwords     = { dc01 = "MockOnly!2026-Not-A-Real-Secret", dc02 = "MockOnly!2026-Not-A-Real-Secret" }
  }
  assert {
    condition     = length(module.external_identity) == 1 && length(module.external_identity[0].domain_controller_ids) == 2 && length(module.external_identity[0].dc_backup_protected_vm_ids) == 2 && length(module.external_identity[0].domain_join_extension_ids) == 0
    error_message = "Two DCs and backups must compose without Terraform-owned promotion or member-server domain join."
  }
}
run "missing_backup_approval_blocks_identity_deployment" {
  command = plan
  variables {
    enabled             = true
    deployment_approved = true
    dc_backup           = null
    admin_passwords     = { dc01 = "MockOnly!2026-Not-A-Real-Secret", dc02 = "MockOnly!2026-Not-A-Real-Secret" }
  }
  expect_failures = [terraform_data.approval]
}
run "default_route_alone_cannot_prove_inspection" {
  command = plan
  variables {
    enabled                     = true
    deployment_approved         = true
    inspection_address_prefixes = []
    admin_passwords             = { dc01 = "MockOnly!2026-Not-A-Real-Secret", dc02 = "MockOnly!2026-Not-A-Real-Secret" }
  }
  expect_failures = [terraform_data.approval]
}
run "wrong_firewall_target_is_rejected" {
  command = plan
  variables {
    enabled                = true
    deployment_approved    = true
    inspection_next_hop_ip = "10.102.0.5"
    admin_passwords        = { dc01 = "MockOnly!2026-Not-A-Real-Secret", dc02 = "MockOnly!2026-Not-A-Real-Secret" }
  }
  expect_failures = [terraform_data.approval]
}
run "legacy_external_identity_owner_must_be_checked" {
  command = plan
  variables {
    enabled                         = true
    deployment_approved             = true
    existing_identity_owner_checked = false
    admin_passwords                 = { dc01 = "MockOnly!2026-Not-A-Real-Secret", dc02 = "MockOnly!2026-Not-A-Real-Secret" }
  }
  expect_failures = [terraform_data.approval]
}
run "external_dc_owner_composes_optional_private_ama" {
  command = plan
  variables {
    enabled             = true
    deployment_approved = true
    admin_passwords     = { dc01 = "MockOnly!2026-Not-A-Real-Secret", dc02 = "MockOnly!2026-Not-A-Real-Secret" }
    domain_controllers = { for key, dc in var.domain_controllers : key => merge(dc, {
      identity = {
        type         = "SystemAssigned, UserAssigned"
        identity_ids = ["/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/identity-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/ama-mi"]
      }
    }) }
    phase2_agent_ownership_confirmed  = true
    phase2_log_analytics_workspace_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.OperationalInsights/workspaces/central-law"
    phase2_agents = { dc01 = {
      os_type                     = "Windows"
      managed_identity_id         = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/identity-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/ama-mi"
      identity_and_network_ready  = true
      data_collection_rules       = { baseline = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.Insights/dataCollectionRules/windows-events" }
      private_ingestion_enabled   = true
      data_collection_endpoint_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.Insights/dataCollectionEndpoints/private-dce"
      private_link_scope_ready    = true
    } }
  }
  assert {
    condition     = length(module.phase2_vm_observability[0].agent_ids) == 1 && length(module.phase2_vm_observability[0].endpoint_association_ids) == 1
    error_message = "The external identity owner must resolve VM IDs itself and support private AMA without moving core DC resources."
  }
}
