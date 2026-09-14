mock_provider "azurerm" {}
run "disabled_is_noop" {
  command = plan
  assert {
    condition     = length(azurerm_consumption_budget_resource_group.resource_group_budget) == 0 && length(azurerm_consumption_budget_subscription.subscription_budget) == 0 && length(azurerm_consumption_budget_management_group.management_group_budget) == 0
    error_message = "no budget when no scope selected"
  }
}

run "creates_subscription_budget" {
  command = apply
  variables {
    scope_type      = "subscription"
    subscription_id = "00000000-0000-0000-0000-000000000000"
    budget_name     = "monthly-cap"
    amount          = 5000
    start_date      = "2026-01-01T00:00:00Z"
    time_grain      = "Monthly"
    notifications = {
      warn = { operator = "GreaterThan", threshold = 80, threshold_type = "Actual", contact_emails = ["finops@example.com"], enabled = true }
    }
  }
  assert {
    condition     = length(azurerm_consumption_budget_subscription.subscription_budget) == 1
    error_message = "subscription budget should be created"
  }
}
