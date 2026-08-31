mock_provider "azurerm" {}

variables {
  name                       = "kv-diag"
  target_resource_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv"
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mgmt/providers/Microsoft.OperationalInsights/workspaces/law"
  logs = {
    audit = { category_group = "audit" }
    all   = { category_group = "allLogs" }
  }
  metrics = {
    all = { category = "AllMetrics" }
  }
}

run "create" {
  command = apply
  assert {
    condition     = length(azurerm_monitor_diagnostic_setting.this.enabled_log) == 2
    error_message = "expected two enabled_log blocks"
  }
  assert {
    condition     = length(azurerm_monitor_diagnostic_setting.this.enabled_metric) == 1
    error_message = "expected one enabled_metric block"
  }
}

run "rejects_no_destination" {
  command = plan
  variables {
    log_analytics_workspace_id = null
  }
  expect_failures = [azurerm_monitor_diagnostic_setting.this]
}

run "rejects_log_with_both_category_and_group" {
  command = plan
  variables {
    logs = { bad = { category = "AuditEvent", category_group = "audit" } }
  }
  expect_failures = [var.logs]
}

run "rejects_bad_destination_type" {
  command = plan
  variables {
    log_analytics_destination_type = "Legacy"
  }
  expect_failures = [var.log_analytics_destination_type]
}
