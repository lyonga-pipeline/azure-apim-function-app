mock_provider "azurerm" {}
variables { subscription_id = "11111111-1111-1111-1111-111111111111" }
run "defaults_do_not_modify_governance" {
  command = plan
  assert {
    condition     = length(azurerm_consumption_budget_subscription.subscription) + length(azurerm_management_group_policy_assignment.audit) + length(azurerm_policy_definition.sandbox_expiry) == 0
    error_message = "Phase 2 approval is opt-in."
  }
}
run "audit_only_and_separate_finops" {
  command = plan
  variables {
    audit_initiatives = { regulatory = { name = "regulatory-audit", management_group_id = "/providers/Microsoft.Management/managementGroups/enterprise", policy_set_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/22222222-2222-2222-2222-222222222222", approval_reference = "EXAMPLE-GRC-APPROVAL" } }
    budgets           = { monthly = { name = "monthly", amount = 5000, start_date = "2026-10-01T00:00:00Z", end_date = "2030-10-01T00:00:00Z", contact_emails = ["finops@example.invalid"], approval_reference = "EXAMPLE-FINOPS-APPROVAL" } }
    sandbox_scope     = { management_group_id = "/providers/Microsoft.Management/managementGroups/sandbox", approval_reference = "EXAMPLE-SANDBOX-APPROVAL" }
  }
  assert {
    condition     = azurerm_management_group_policy_assignment.audit["regulatory"].enforce == false && length(azurerm_consumption_budget_subscription.subscription["monthly"].notification) == 3 && jsondecode(azurerm_policy_definition.sandbox_expiry["sandbox"].policy_rule).then.effect == "Audit"
    error_message = "Initial audit must not block/mutate resources; budgets remain outside spokes."
  }
}
run "approved_expiring_exemption" {
  command = plan
  variables {
    exemptions = { private_ingress = { name = "approved-pilot", scope_type = "resource", scope_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/network-rg/providers/Microsoft.Network/publicIPAddresses/pilot", policy_assignment_id = "/providers/Microsoft.Management/managementGroups/enterprise/providers/Microsoft.Authorization/policyAssignments/deny-pip", justification = "Approved Phase 3 pilot.", approved_by = "security@example.invalid", ticket = "EXAMPLE-CHG-123", expires_on = "2030-01-01T00:00:00Z" } }
  }
  assert {
    condition     = length(azurerm_resource_policy_exemption.resource) == 1
    error_message = "Resource-scoped waivers need expiry and approval metadata."
  }
}
run "expired_exemption_rejected" {
  command = plan
  variables {
    exemptions = { old = { name = "old", scope_type = "subscription", scope_id = "/subscriptions/11111111-1111-1111-1111-111111111111", policy_assignment_id = "/providers/Microsoft.Management/managementGroups/enterprise/providers/Microsoft.Authorization/policyAssignments/baseline", justification = "Test", approved_by = "security", ticket = "EXAMPLE-CHG", expires_on = "2000-01-01T00:00:00Z" } }
  }
  expect_failures = [terraform_data.expiry]
}
run "zero_budget_rejected" {
  command = plan
  variables {
    budgets = { invalid = { name = "monthly", amount = 0, start_date = "2026-10-01T00:00:00Z", end_date = "2030-10-01T00:00:00Z", contact_emails = ["finops@example.invalid"], approval_reference = "EXAMPLE-APPROVAL" } }
  }
  expect_failures = [var.budgets]
}
run "cost_export_and_anomaly_are_separately_opt_in" {
  command = plan
  variables {
    cost_exports = { daily = {
      name             = "daily-actual", container_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/finops-rg/providers/Microsoft.Storage/storageAccounts/finops/blobServices/default/containers/costs",
      root_folder_path = "subscriptions/pilot", start_date = "2026-10-01T00:00:00Z", end_date = "2030-10-01T00:00:00Z", export_access_confirmed = true
    } }
    cost_anomalies = { pilot = { name = "cost-anomalies", email_addresses = ["finops@example.invalid"] } }
  }
  assert {
    condition     = length(azurerm_subscription_cost_management_export.cost) == 1 && length(azurerm_cost_anomaly_alert.subscription) == 1
    error_message = "Cost exports and anomaly alerts must create actual subscription resources."
  }
}
