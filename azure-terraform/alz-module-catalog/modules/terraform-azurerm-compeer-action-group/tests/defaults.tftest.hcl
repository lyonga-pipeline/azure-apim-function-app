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
    condition     = length(azurerm_monitor_action_group.action_group.email_receiver) == 2
    error_message = "expected two email receivers"
  }
  assert {
    condition     = azurerm_monitor_action_group.action_group.email_receiver[0].use_common_alert_schema == true
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
    condition     = length(azurerm_monitor_action_group.action_group.email_receiver) == 3
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

run "rejects_empty_short_name" {
  # Only the too-long side of the 1-12 char validation had a test.
  command = plan
  variables {
    short_name = ""
  }
  expect_failures = [var.short_name]
}

run "sms_and_voice_receivers_render" {
  # Only email/webhook had ever been exercised out of the 11 receiver
  # types - sms/voice are two more of the simpler ones, giving smoke
  # coverage beyond just the first two.
  command = apply
  variables {
    receivers = {
      sms   = { oncall = { country_code = "1", phone_number = "5555550100" } }
      voice = { oncall = { country_code = "1", phone_number = "5555550101" } }
    }
  }

  assert {
    condition     = length(azurerm_monitor_action_group.action_group.sms_receiver) == 1 && length(azurerm_monitor_action_group.action_group.voice_receiver) == 1
    error_message = "sms and voice receivers should each render one block"
  }
}

run "enabled_false_is_respected" {
  command = plan
  variables {
    enabled = false
  }

  assert {
    condition     = azurerm_monitor_action_group.action_group.enabled == false
    error_message = "enabled = false should be passed through, not silently forced true"
  }
}

run "outputs_are_wired" {
  command = apply

  assert {
    condition     = output.id == azurerm_monitor_action_group.action_group.id && output.name == azurerm_monitor_action_group.action_group.name
    error_message = "id/name outputs must echo the resource"
  }
  assert {
    condition     = output.short_name == azurerm_monitor_action_group.action_group.short_name && output.enabled == azurerm_monitor_action_group.action_group.enabled
    error_message = "short_name/enabled outputs must echo the resource attributes"
  }
}
