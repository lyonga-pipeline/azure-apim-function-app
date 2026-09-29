mock_provider "azurerm" {}

variables {
  name                = "dcr-platform"
  resource_group_name = "rg-mon"
  location            = "eastus2"
  destinations = {
    log_analytics = {
      law = {
        name                  = "law-dest"
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/law"
      }
    }
  }
  data_flows = {
    perf = {
      streams      = ["Microsoft-Perf"]
      destinations = ["law-dest"]
    }
  }
}

run "accepts_valid_kind_and_identity" {
  command = plan
  variables {
    kind     = "Windows"
    identity = { type = "SystemAssigned" }
  }
  assert {
    condition     = azurerm_monitor_data_collection_rule.rule.kind == "Windows"
    error_message = "valid kind should be accepted"
  }
}

run "rejects_bad_kind" {
  command = plan
  variables {
    kind = "MacOS"
  }
  expect_failures = [var.kind]
}

run "rejects_bad_identity_type" {
  command = plan
  variables {
    identity = { type = "SystemAssigned, UserAssigned" } # not valid for this resource, unlike RSV
  }
  expect_failures = [var.identity]
}

run "accepts_valid_performance_counter_sampling_frequency" {
  command = plan
  variables {
    data_sources = {
      performance_counter = {
        cpu = {
          name                          = "cpu-counters"
          streams                       = ["Microsoft-Perf"]
          sampling_frequency_in_seconds = 60
          counter_specifiers            = ["\\Processor(_Total)\\% Processor Time"]
        }
      }
    }
  }
  assert {
    condition     = azurerm_monitor_data_collection_rule.rule.name == "dcr-platform"
    error_message = "valid performance_counter sampling frequency should not block plan"
  }
}

run "rejects_sampling_frequency_over_maximum" {
  command = plan
  variables {
    data_sources = {
      performance_counter = {
        cpu = {
          name                          = "cpu-counters"
          streams                       = ["Microsoft-Perf"]
          sampling_frequency_in_seconds = 1801
          counter_specifiers            = ["\\Processor(_Total)\\% Processor Time"]
        }
      }
    }
  }
  expect_failures = [var.data_sources]
}

run "rejects_unsupported_syslog_facility_name" {
  command = plan
  variables {
    data_sources = {
      syslog = {
        sys = {
          name           = "syslog-default"
          streams        = ["Microsoft-Syslog"]
          facility_names = ["not-a-real-facility"]
          log_levels     = ["Info"]
        }
      }
    }
  }
  expect_failures = [var.data_sources]
}

run "rejects_unsupported_syslog_log_level" {
  command = plan
  variables {
    data_sources = {
      syslog = {
        sys = {
          name           = "syslog-default"
          streams        = ["Microsoft-Syslog"]
          facility_names = ["auth"]
          log_levels     = ["Verbose"]
        }
      }
    }
  }
  expect_failures = [var.data_sources]
}

run "rejects_unsupported_stream_declaration_column_type" {
  command = plan
  variables {
    stream_declarations = {
      Custom-MyStream = {
        columns = {
          TimeGenerated = { type = "datetime" }
          Message       = { type = "text" } # not a real DCR column type
        }
      }
    }
  }
  expect_failures = [var.stream_declarations]
}
