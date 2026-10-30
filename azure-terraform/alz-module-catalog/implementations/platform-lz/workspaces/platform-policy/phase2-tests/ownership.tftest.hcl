# =============================================================================
# PHASE 2 CHANGES - additive, opt-in; preserve existing resource/state ownership.
# Copy this file together with the PHASE 2 section in main.tf and the example.
# =============================================================================
mock_provider "azurerm" {}
mock_provider "tfe" {}
variables {
  tenant_id                 = "00000000-0000-0000-0000-000000000000"
  execution_subscription_id = "11111111-1111-1111-1111-111111111111"
  use_tfe_outputs           = false
  policy                    = { enabled = true }
  phase2_audit_initiatives  = {}
  phase2_exemptions         = {}
}
run "policy_extension_is_opt_in" {
  command = plan
  variables { phase2_sandbox_scope = null }
  assert {
    condition     = length(module.policy) == 1 && length(module.phase2_policy) == 0
    error_message = "Existing policy owner must be preserved with no Phase 2 resources by default."
  }
}
run "sandbox_pilot_is_owned_by_policy_not_finops" {
  command = plan
  assert {
    condition     = length(module.phase2_policy) == 1 && length(module.phase2_policy[0].budget_ids) == 0 && length(module.phase2_policy[0].cost_export_ids) == 0
    error_message = "Policy workspace must not acquire FinOps resources."
  }
}
run "audit_assignment_uses_same_policy_workspace" {
  command = plan
  variables {
    phase2_sandbox_scope = null
    phase2_audit_initiatives = { approved = {
      name                     = "approved-audit", management_group_id = "/providers/Microsoft.Management/managementGroups/compeer-enterprise-mg"
      policy_set_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/11111111-2222-3333-4444-555555555555"
      approval_reference       = "MOCK-APPROVAL"
    } }
  }
  assert {
    condition     = length(module.phase2_policy[0].audit_assignment_ids) == 1
    error_message = "Approved regulatory rollout must use the existing policy workspace."
  }
}
run "existing_exemption_is_not_duplicated" {
  command = plan
  variables {
    phase2_sandbox_scope = null
    policy = { enabled = true, policy_exemptions = { retained = {
      scope_type           = "subscription", subscription_id = "/subscriptions/11111111-1111-1111-1111-111111111111"
      management_group_id  = "/providers/Microsoft.Management/managementGroups/compeer-enterprise-mg"
      policy_assignment_id = "/providers/Microsoft.Management/managementGroups/compeer-enterprise-mg/providers/Microsoft.Authorization/policyAssignments/old"
    } } }
    phase2_exemptions = { new_key = {
      name                 = "retained", scope_type = "subscription", scope_id = "/subscriptions/11111111-1111-1111-1111-111111111111"
      policy_assignment_id = "/providers/Microsoft.Management/managementGroups/compeer-enterprise-mg/providers/Microsoft.Authorization/policyAssignments/old"
      justification        = "mock", approved_by = "mock", ticket = "mock", expires_on = "2030-01-31T00:00:00Z"
    } }
  }
  expect_failures = [terraform_data.phase2_policy_contract]
}
