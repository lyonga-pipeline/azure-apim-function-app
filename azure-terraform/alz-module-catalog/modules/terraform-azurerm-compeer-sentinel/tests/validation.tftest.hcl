mock_provider "azurerm" {}

variables {
  enabled                    = true
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mgmt/providers/Microsoft.OperationalInsights/workspaces/law"
}

run "accepts_valid_scheduled_alert_rule" {
  command = plan
  variables {
    scheduled_alert_rules = {
      failed_logins = {
        display_name      = "Excessive failed logins"
        severity          = "High"
        query             = "SigninLogs | where ResultType != 0"
        query_frequency   = "PT1H"
        query_period      = "P1D"
        trigger_operator  = "GreaterThan"
        trigger_threshold = 10
      }
    }
  }
  assert {
    condition     = azurerm_sentinel_alert_rule_scheduled.scheduled_rule["failed_logins"].severity == "High"
    error_message = "valid severity should be accepted"
  }
}

run "rejects_bad_severity" {
  command = plan
  variables {
    scheduled_alert_rules = {
      bad = {
        display_name = "Bad rule"
        severity     = "Critical" # not a valid Sentinel severity
        query        = "SigninLogs"
      }
    }
  }
  expect_failures = [var.scheduled_alert_rules]
}

run "rejects_bad_trigger_operator" {
  command = plan
  variables {
    scheduled_alert_rules = {
      bad = {
        display_name     = "Bad rule"
        severity         = "Low"
        query            = "SigninLogs"
        trigger_operator = "GreaterThanOrEqual" # not supported by this resource
      }
    }
  }
  expect_failures = [var.scheduled_alert_rules]
}

run "rejects_malformed_query_frequency" {
  command = plan
  variables {
    scheduled_alert_rules = {
      bad = {
        display_name    = "Bad rule"
        severity        = "Low"
        query           = "SigninLogs"
        query_frequency = "1h" # must be ISO-8601 (PT1H)
      }
    }
  }
  expect_failures = [var.scheduled_alert_rules]
}
