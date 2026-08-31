mock_provider "azurerm" {}
run "disabled_is_noop" {
  command = plan
  assert {
    condition     = length(azurerm_consumption_budget_resource_group.this) == 0 && length(azurerm_consumption_budget_subscription.this) == 0 && length(azurerm_consumption_budget_management_group.this) == 0
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
    condition     = length(azurerm_consumption_budget_subscription.this) == 1
    error_message = "subscription budget should be created"
  }
}
