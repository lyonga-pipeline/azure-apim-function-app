mock_provider "azurerm" {}

variables {
  name                = "ag-platform-test"
  resource_group_name = "rg-mon-test"
  short_name          = "platform"
}

run "create_with_receivers" {
  command = apply

  variables {
    receivers = {
      email = {
        oncall = { email_address = "oncall@example.com" }
        sre    = { email_address = "sre@example.com" }
      }
      webhook = {
        pagerduty = { service_uri = "https://events.pagerduty.com/integration/abc/enqueue" }
      }
    }
  }

  assert {
    condition     = length(azurerm_monitor_action_group.this.email_receiver) == 2
    error_message = "expected two email receivers"
  }
  assert {
    condition     = azurerm_monitor_action_group.this.email_receiver[0].use_common_alert_schema == true
    error_message = "use_common_alert_schema should default true"
  }
}

run "add_receiver_is_additive" {
  command = apply

  variables {
    receivers = {
      email = {
        oncall = { email_address = "oncall@example.com" }
        sre    = { email_address = "sre@example.com" }
        new    = { email_address = "new@example.com" }
      }
    }
  }

  assert {
    condition     = length(azurerm_monitor_action_group.this.email_receiver) == 3
    error_message = "adding a receiver key adds one receiver"
  }
}

run "rejects_long_short_name" {
  command = plan
  variables {
    short_name = "waytoolongshortname"
  }
  expect_failures = [var.short_name]
}
