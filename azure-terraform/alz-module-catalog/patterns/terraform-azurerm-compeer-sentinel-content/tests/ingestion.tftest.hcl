mock_provider "azurerm" {
  # Rule associations and role assignments parse resource IDs.
  mock_resource "azurerm_monitor_data_collection_rule" {
    defaults = {
      id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mgmt/providers/Microsoft.Insights/dataCollectionRules/dcr-mock"
      immutable_id = "dcr-00000000000000000000000000000000"
    }
  }
  mock_resource "azurerm_monitor_data_collection_endpoint" {
    defaults = {
      id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mgmt/providers/Microsoft.Insights/dataCollectionEndpoints/dce-mock"
      logs_ingestion_endpoint = "https://dce-mock.centralus-1.ingest.monitor.azure.com"
    }
  }
}

variables {
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mgmt/providers/Microsoft.OperationalInsights/workspaces/law-platform"
  tenant_id                  = "11111111-1111-1111-1111-111111111111"
  ingestion = {
    resource_group_name = "rg-mgmt"
    location            = "centralus"
    endpoints = {
      logs = { public_network_access_enabled = true }
    }
    custom_tables = {
      Cloudflare_CL = {
        retention_in_days       = 90
        total_retention_in_days = 548
        columns = [
          { name = "TimeGenerated", type = "dateTime" },
          { name = "ClientIP", type = "string" },
          { name = "EdgeStatus", type = "int" },
          { name = "Raw", type = "dynamic" },
        ]
      }
    }
    rules = {
      cloudflare = {
        preset                  = "custom_ingestion"
        endpoint_key            = "logs"
        table_key               = "Cloudflare_CL"
        publisher_principal_ids = ["22222222-2222-2222-2222-222222222222"]
      }
    }
  }
}

run "cribl_cloudflare_path_is_wired_end_to_end" {
  command = apply

  assert {
    condition = (
      azurerm_log_analytics_workspace_table_custom_log.table["Cloudflare_CL"].total_retention_in_days == 548 &&
      length(azurerm_log_analytics_workspace_table_custom_log.table["Cloudflare_CL"].column) == 4
    )
    error_message = "the custom table must carry the 90/548 retention and its columns"
  }
  assert {
    condition = (
      output.ingestion_targets["cloudflare"].stream_name == "Custom-Cloudflare_CL" &&
      output.ingestion_targets["cloudflare"].table == "Cloudflare_CL" &&
      output.ingestion_targets["cloudflare"].logs_ingestion_url == "https://dce-mock.centralus-1.ingest.monitor.azure.com" &&
      output.ingestion_targets["cloudflare"].dcr_immutable_id != null
    )
    error_message = "ingestion_targets must give the pipeline the endpoint, stream name and immutable ID"
  }
  assert {
    condition     = contains(output.source_coverage.available, "Cloudflare_CL")
    error_message = "a custom table fed by an ingestion rule must become an available telemetry source"
  }
  assert {
    condition     = length(output.data_collection_rule_ids) == 1 && length(output.custom_table_ids) == 1 && length(output.data_collection_endpoint_ids) == 1
    error_message = "the endpoint, table and rule must be created and published"
  }
}

run "a_rule_reading_the_custom_table_is_allowed_once_the_pipeline_exists" {
  command = plan
  variables {
    scheduled_rules = {
      cloudflare-waf = {
        display_name     = "Cloudflare WAF block spike"
        severity         = "Medium"
        query            = "Cloudflare_CL | where EdgeStatus == 403"
        requires_sources = ["Cloudflare_CL"]
      }
    }
  }

  assert {
    condition     = length(output.source_coverage.unmet) == 0
    error_message = "a rule that reads a custom table created here must be allowed"
  }
}

run "a_rule_reading_an_undeclared_custom_table_fails_the_plan" {
  command = plan
  variables {
    ingestion = null
    scheduled_rules = {
      cloudflare-waf = {
        display_name     = "Cloudflare WAF block spike"
        severity         = "Medium"
        query            = "Cloudflare_CL | take 1"
        requires_sources = ["Cloudflare_CL"]
      }
    }
  }
  expect_failures = [terraform_data.source_dependency_contract]
}

run "transform_into_the_table_from_a_raw_input_stream" {
  command = plan
  variables {
    ingestion = {
      resource_group_name = "rg-mgmt"
      location            = "centralus"
      endpoints           = { logs = { public_network_access_enabled = true } }
      custom_tables = {
        Cloudflare_CL = { columns = [{ name = "TimeGenerated", type = "dateTime" }, { name = "ClientIP", type = "string" }] }
      }
      rules = {
        cloudflare = {
          preset            = "custom_ingestion"
          endpoint_key      = "logs"
          table_key         = "Cloudflare_CL"
          input_stream_name = "Custom-CloudflareRaw"
          stream_columns    = [{ name = "ts", type = "datetime" }, { name = "client", type = "string" }]
          transform_kql     = "source | project TimeGenerated = ts, ClientIP = client"
        }
      }
    }
  }

  assert {
    condition = (
      azurerm_monitor_data_collection_rule.rule["cloudflare"].data_flow[0].output_stream == "Custom-Cloudflare_CL" &&
      output.ingestion_targets["cloudflare"].stream_name == "Custom-CloudflareRaw"
    )
    error_message = "a raw input stream must flow into the table through output_stream"
  }
}

run "agent_feeds_become_sources_only_when_attached" {
  command = plan
  variables {
    ingestion = {
      resource_group_name = "rg-mgmt"
      location            = "centralus"
      rules = {
        dc-security  = { preset = "windows_security_events" }
        palo-alto    = { preset = "cef", facility_names = ["local4"] }
        linux-syslog = { preset = "syslog", facility_names = ["auth", "authpriv"], log_levels = ["Warning", "Error", "Critical"] }
      }
      associations = {
        dc01 = { rule_key = "dc-security", target_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-identity/providers/Microsoft.Compute/virtualMachines/dc01" }
        pan1 = { rule_key = "palo-alto", target_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-conn/providers/Microsoft.Compute/virtualMachines/cef-fwd1" }
      }
    }
  }

  assert {
    condition = (
      contains(output.source_coverage.available, "windows_security_events") &&
      contains(output.source_coverage.available, "common_security_log") &&
      !contains(output.source_coverage.available, "syslog")
    )
    error_message = "an agent rule is a delivered source only once it has an association; the unattached syslog rule is not"
  }
  assert {
    condition = (
      azurerm_monitor_data_collection_rule.rule["dc-security"].kind == "Windows" &&
      azurerm_monitor_data_collection_rule.rule["palo-alto"].kind == "Linux"
    )
    error_message = "Windows presets must produce Windows rules and syslog/CEF presets Linux rules"
  }
}

run "baseline_palo_alto_rule_is_satisfied_by_an_attached_cef_rule" {
  command = plan
  variables {
    scheduled_rules = {
      pan-down = {
        display_name     = "CEF stopped"
        severity         = "High"
        query            = "CommonSecurityLog | take 1"
        requires_sources = ["common_security_log"]
      }
    }
    ingestion = {
      resource_group_name = "rg-mgmt"
      location            = "centralus"
      rules               = { palo-alto = { preset = "cef", facility_names = ["local4"] } }
      associations        = { pan1 = { rule_key = "palo-alto", target_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-conn/providers/Microsoft.Compute/virtualMachines/cef-fwd1" } }
    }
  }

  assert {
    condition     = length(output.source_coverage.unmet) == 0
    error_message = "a CEF rule with an attached forwarder must satisfy a CommonSecurityLog requirement"
  }
}

run "rejects_custom_table_without_time_generated" {
  command = plan
  variables {
    ingestion = {
      resource_group_name = "rg-mgmt"
      location            = "centralus"
      custom_tables       = { Cloudflare_CL = { columns = [{ name = "ClientIP", type = "string" }] } }
    }
  }
  expect_failures = [var.ingestion]
}

run "rejects_custom_table_name_without_suffix" {
  command = plan
  variables {
    ingestion = {
      resource_group_name = "rg-mgmt"
      location            = "centralus"
      custom_tables       = { Cloudflare = { columns = [{ name = "TimeGenerated", type = "dateTime" }] } }
    }
  }
  expect_failures = [var.ingestion]
}

run "rejects_retention_on_a_basic_plan_table" {
  command = plan
  variables {
    ingestion = {
      resource_group_name = "rg-mgmt"
      location            = "centralus"
      custom_tables       = { Cloudflare_CL = { plan = "Basic", retention_in_days = 90, columns = [{ name = "TimeGenerated", type = "dateTime" }] } }
    }
  }
  expect_failures = [var.ingestion]
}

run "rejects_total_retention_shorter_than_analytics_retention" {
  command = plan
  variables {
    ingestion = {
      resource_group_name = "rg-mgmt"
      location            = "centralus"
      custom_tables       = { Cloudflare_CL = { retention_in_days = 90, total_retention_in_days = 30, columns = [{ name = "TimeGenerated", type = "dateTime" }] } }
    }
  }
  expect_failures = [var.ingestion]
}

run "rejects_unknown_preset" {
  command = plan
  variables {
    ingestion = {
      resource_group_name = "rg-mgmt"
      location            = "centralus"
      rules               = { bad = { preset = "netflow" } }
    }
  }
  expect_failures = [var.ingestion]
}

run "rejects_custom_ingestion_without_a_table" {
  command = plan
  variables {
    ingestion = {
      resource_group_name = "rg-mgmt"
      location            = "centralus"
      endpoints           = { logs = { public_network_access_enabled = true } }
      rules               = { bad = { preset = "custom_ingestion", endpoint_key = "logs" } }
    }
  }
  expect_failures = [var.ingestion]
}

run "rejects_custom_ingestion_without_an_endpoint" {
  command = plan
  variables {
    ingestion = {
      resource_group_name = "rg-mgmt"
      location            = "centralus"
      custom_tables       = { Cloudflare_CL = { columns = [{ name = "TimeGenerated", type = "dateTime" }] } }
      rules               = { bad = { preset = "custom_ingestion", table_key = "Cloudflare_CL" } }
    }
  }
  expect_failures = [var.ingestion]
}

run "rejects_pipeline_settings_on_an_agent_rule" {
  command = plan
  variables {
    ingestion = {
      resource_group_name = "rg-mgmt"
      location            = "centralus"
      rules               = { bad = { preset = "windows_security_events", transform_kql = "source" } }
    }
  }
  expect_failures = [var.ingestion]
}

run "rejects_syslog_without_facilities" {
  command = plan
  variables {
    ingestion = {
      resource_group_name = "rg-mgmt"
      location            = "centralus"
      rules               = { bad = { preset = "cef" } }
    }
  }
  expect_failures = [var.ingestion]
}

run "rejects_unknown_syslog_facility" {
  command = plan
  variables {
    ingestion = {
      resource_group_name = "rg-mgmt"
      location            = "centralus"
      rules               = { bad = { preset = "syslog", facility_names = ["local9"] } }
    }
  }
  expect_failures = [var.ingestion]
}

run "rejects_windows_events_without_xpath" {
  command = plan
  variables {
    ingestion = {
      resource_group_name = "rg-mgmt"
      location            = "centralus"
      rules               = { bad = { preset = "windows_events" } }
    }
  }
  expect_failures = [var.ingestion]
}

run "rejects_endpoint_key_that_does_not_exist" {
  command = plan
  variables {
    ingestion = {
      resource_group_name = "rg-mgmt"
      location            = "centralus"
      rules               = { bad = { preset = "syslog", facility_names = ["auth"], endpoint_key = "nope" } }
    }
  }
  expect_failures = [var.ingestion]
}

run "rejects_association_to_an_unknown_rule" {
  command = plan
  variables {
    ingestion = {
      resource_group_name = "rg-mgmt"
      location            = "centralus"
      associations        = { bad = { rule_key = "nope", target_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Compute/virtualMachines/vm" } }
    }
  }
  expect_failures = [var.ingestion]
}

run "rejects_association_with_a_non_resource_id" {
  command = plan
  variables {
    ingestion = {
      resource_group_name = "rg-mgmt"
      location            = "centralus"
      rules               = { r = { preset = "syslog", facility_names = ["auth"] } }
      associations        = { bad = { rule_key = "r", target_resource_id = "vm-1" } }
    }
  }
  expect_failures = [var.ingestion]
}

run "additional_connectors_are_created" {
  command = apply
  variables {
    ingestion = null
    data_connectors = {
      office_irm = true
      power_bi   = true
    }
  }

  assert {
    condition     = length(output.connector_ids) == 2 && contains(output.source_coverage.available, "office_activity")
    error_message = "Insider Risk Management and Power BI connectors must be created and provide office_activity"
  }
}
