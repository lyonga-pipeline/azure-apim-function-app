mock_provider "azurerm" {}

variables {
  log_analytics_workspace_name    = "law-platform"
  resource_group_name             = "rg-mgmt"
  location                        = "eastus2"
  log_analytics_sku               = "PerGB2018"
  log_analytics_retention_in_days = 90
}

run "create" {
  command = apply
  assert {
    condition     = azurerm_log_analytics_workspace.logs.retention_in_days == 90
    error_message = "retention not wired"
  }
}

run "rejects_bad_retention" {
  command = plan
  variables {
    log_analytics_retention_in_days = 5000
  }
  expect_failures = [var.log_analytics_retention_in_days]
}
