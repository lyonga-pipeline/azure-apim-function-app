mock_provider "azurerm" {}
run "empty_finops_does_not_manage_policy_or_cost" {
  command = plan
  assert {
    condition     = length(module.finops.budget_ids) == 0 && length(module.finops.audit_assignment_ids) == 0
    error_message = "An unapproved FinOps root creates no resources and never manages MG policy."
  }
}
run "finops_requires_existing_owner_review" {
  command = plan
  variables {
    cost_anomalies = { test = { name = "test", email_addresses = ["finops@example.invalid"] } }
  }
  expect_failures = [terraform_data.finops_contract]
}
run "existing_budget_name_cannot_be_duplicated" {
  command = plan
  variables {
    ownership_confirmed   = true
    existing_budget_names = ["retained-budget"]
    budgets = { duplicate = {
      name           = "retained-budget", amount = 5000, start_date = "2026-10-01T00:00:00Z", end_date = "2030-10-01T00:00:00Z"
      contact_emails = ["finops@example.invalid"], approval_reference = "MOCK-APPROVAL"
    } }
  }
  expect_failures = [terraform_data.finops_contract]
}
