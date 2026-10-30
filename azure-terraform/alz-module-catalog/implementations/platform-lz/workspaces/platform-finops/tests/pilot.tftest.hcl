mock_provider "azurerm" {}
run "enabled_finops_has_no_policy_ownership" {
  command = plan
  assert {
    condition     = length(module.finops.budget_ids) == 1 && length(module.finops.cost_export_ids) == 1 && length(module.finops.audit_assignment_ids) == 0 && length(module.finops.exemption_ids) == 0
    error_message = "FinOps may manage budgets/exports, never policy assignments or exemptions."
  }
}
