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

run "windows_event_log_data_source_renders" {
  # Of 10 data_sources types, only performance_counter and syslog had ever
  # been exercised - this adds smoke coverage for windows_event_log too.
  command = apply
  variables {
    data_sources = {
      windows_event_log = {
        app = {
          name           = "app-events"
          streams        = ["Microsoft-WindowsEvent"]
          x_path_queries = ["Application!*[System[(Level=2)]]"]
        }
      }
    }
  }

  assert {
    condition     = length(azurerm_monitor_data_collection_rule.rule.data_sources[0].windows_event_log) == 1
    error_message = "windows_event_log data source should render"
  }
}

run "azure_monitor_metrics_destination_renders" {
  # Of 8 destinations sub-blocks, only log_analytics had ever been used.
  command = apply
  variables {
    destinations = {
      log_analytics = {
        law = {
          name                  = "law-dest"
          workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/law"
        }
      }
      azure_monitor_metrics = {
        amw = { name = "metrics-dest" }
      }
    }
  }

  assert {
    condition     = length(azurerm_monitor_data_collection_rule.rule.destinations[0].azure_monitor_metrics) == 1
    error_message = "azure_monitor_metrics destination should render"
  }
}

run "outputs_are_wired" {
  command = apply

  assert {
    condition     = output.id == azurerm_monitor_data_collection_rule.rule.id && output.name == azurerm_monitor_data_collection_rule.rule.name
    error_message = "id/name outputs must echo the resource"
  }
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
