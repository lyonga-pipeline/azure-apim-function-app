mock_provider "azurerm" {}

variables {
  enabled                    = true
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mgmt/providers/Microsoft.OperationalInsights/workspaces/law"
}

run "onboard" {
  command = apply
  assert {
    condition     = length(azurerm_sentinel_log_analytics_workspace_onboarding.this) == 1
    error_message = "Sentinel should be onboarded when enabled"
  }
}

run "disabled_is_noop" {
  command = plan
  variables {
    enabled = false
  }
  assert {
    condition     = length(azurerm_sentinel_log_analytics_workspace_onboarding.this) == 0
    error_message = "nothing onboarded when disabled"
  }
}
