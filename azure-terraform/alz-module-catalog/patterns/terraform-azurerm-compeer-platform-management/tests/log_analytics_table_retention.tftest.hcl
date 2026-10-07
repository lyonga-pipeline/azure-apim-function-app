mock_provider "azurerm" {}

variables {
  subscription_id = "00000000-0000-0000-0000-000000000000"
  location        = "centralus"
  environment     = "prod"
  resource_group  = { name = "rg-mgmt" }
  log_analytics   = { name = "law-platform", retention_in_days = 90 }
  action_group    = { short_name = "mgmt" }
}

run "security_table_retention_is_wired" {
  command = plan

  variables {
    log_analytics_tables = {
      AzureActivity = {
        retention_in_days       = 90
        total_retention_in_days = 548
      }
    }
  }

  assert {
    condition     = azurerm_log_analytics_workspace_table.table_retention["AzureActivity"].retention_in_days == 90
    error_message = "expected 90-day analytics retention"
  }

  assert {
    condition     = azurerm_log_analytics_workspace_table.table_retention["AzureActivity"].total_retention_in_days == 548
    error_message = "expected 1.5-year total retention"
  }
}

run "rejects_total_retention_shorter_than_analytics_retention" {
  command = plan

  variables {
    log_analytics_tables = {
      AzureActivity = {
        retention_in_days       = 90
        total_retention_in_days = 30
      }
    }
  }

  expect_failures = [var.log_analytics_tables]
}
