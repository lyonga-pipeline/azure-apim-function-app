mock_provider "azurerm" {}

variables {
  log_analytics_workspace_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mgmt/providers/Microsoft.OperationalInsights/workspaces/law-platform"
  tenant_id                   = "11111111-1111-1111-1111-111111111111"
  externally_provided_sources = ["azure_activity"]
  scheduled_rules = {
    owner-assigned = {
      display_name = "Owner assigned"
      severity     = "High"
      query        = "AzureActivity | take 1"
      tactics      = ["PrivilegeEscalation"]
      techniques   = ["T1078"]
      entity_mappings = [
        { entity_type = "Account", field_mappings = [{ identifier = "FullName", column_name = "Caller" }] },
      ]
      requires_sources = ["azure_activity"]
    }
  }
}

run "scheduled_rule_is_created_with_documented_defaults" {
  command = apply

  assert {
    condition = (
      azurerm_sentinel_alert_rule_scheduled.scheduled["owner-assigned"].query_frequency == "PT1H" &&
      azurerm_sentinel_alert_rule_scheduled.scheduled["owner-assigned"].trigger_operator == "GreaterThan" &&
      azurerm_sentinel_alert_rule_scheduled.scheduled["owner-assigned"].suppression_enabled == false &&
      azurerm_sentinel_alert_rule_scheduled.scheduled["owner-assigned"].enabled == true
    )
    error_message = "a minimal rule must get hourly frequency, GreaterThan and no suppression"
  }
  assert {
    condition     = length(azurerm_sentinel_alert_rule_scheduled.scheduled["owner-assigned"].entity_mapping) == 1 && length(azurerm_sentinel_alert_rule_scheduled.scheduled["owner-assigned"].incident) == 1
    error_message = "entity mappings and incident creation must be wired"
  }
  assert {
    condition     = contains(keys(output.analytics_rule_ids), "owner-assigned")
    error_message = "the rule must appear in analytics_rule_ids"
  }
}

run "suppression_duration_enables_suppression" {
  command = plan
  variables {
    scheduled_rules = {
      noisy = {
        display_name         = "Noisy"
        severity             = "Low"
        query                = "AzureActivity | take 1"
        suppression_duration = "PT5H"
        requires_sources     = ["azure_activity"]
      }
    }
  }

  assert {
    condition     = azurerm_sentinel_alert_rule_scheduled.scheduled["noisy"].suppression_enabled == true && azurerm_sentinel_alert_rule_scheduled.scheduled["noisy"].suppression_duration == "PT5H"
    error_message = "setting suppression_duration must turn suppression on"
  }
}

run "incident_creation_can_be_disabled" {
  command = plan
  variables {
    scheduled_rules = {
      signal = {
        display_name     = "Volume signal"
        severity         = "Informational"
        query            = "AzureActivity | take 1"
        incident         = { create = false }
        requires_sources = ["azure_activity"]
      }
    }
  }

  assert {
    condition     = length(azurerm_sentinel_alert_rule_scheduled.scheduled["signal"].incident) == 0
    error_message = "incident.create = false must omit the incident block"
  }
}

run "nrt_rule_is_created" {
  command = apply
  variables {
    scheduled_rules = {}
    nrt_rules = {
      breakglass-signin = {
        display_name     = "Break-glass sign-in"
        severity         = "High"
        query            = "SigninLogs | where UserPrincipalName == 'x'"
        requires_sources = ["azure_activity"]
      }
    }
  }

  assert {
    condition     = azurerm_sentinel_alert_rule_nrt.nrt["breakglass-signin"].severity == "High" && contains(keys(output.analytics_rule_ids), "breakglass-signin")
    error_message = "an NRT rule must be created and published"
  }
}

run "microsoft_incident_rule_for_defender_for_cloud" {
  command = apply
  variables {
    scheduled_rules = {}
    data_connectors = { defender_for_cloud = { default = {} } }
    microsoft_incident_rules = {
      defender-for-cloud-high = {
        display_name    = "Defender for Cloud - High and Medium"
        product_filter  = "Azure Security Center"
        severity_filter = ["High", "Medium"]
      }
    }
  }

  assert {
    condition     = azurerm_sentinel_alert_rule_ms_security_incident.microsoft_incident["defender-for-cloud-high"].product_filter == "Azure Security Center"
    error_message = "the Microsoft incident creation rule must be created"
  }
}

run "template_rules_use_the_supplied_guid" {
  command = apply
  variables {
    scheduled_rules = {}
    template_rules = {
      fusion = { kind = "fusion", alert_rule_template = "f71aba3d-28fb-450b-b192-4e76a83015c8" }
    }
  }

  assert {
    condition     = azurerm_sentinel_alert_rule_fusion.fusion["fusion"].alert_rule_template_guid == "f71aba3d-28fb-450b-b192-4e76a83015c8"
    error_message = "a template rule must use the GUID the caller supplied"
  }
}

run "anomaly_rule_defaults_to_flighting" {
  command = plan
  variables {
    scheduled_rules = {}
    anomaly_rules = {
      staging = { display_name = "Potential data staging" }
    }
  }

  assert {
    condition     = azurerm_sentinel_alert_rule_anomaly_built_in.anomaly["staging"].mode == "Flighting"
    error_message = "anomaly rules must start in Flighting"
  }
}

run "rejects_bad_severity" {
  command = plan
  variables {
    scheduled_rules = { bad = { display_name = "x", severity = "Critical", query = "x | take 1" } }
  }
  expect_failures = [var.scheduled_rules]
}

run "rejects_bad_duration" {
  command = plan
  variables {
    scheduled_rules = { bad = { display_name = "x", severity = "Low", query = "x | take 1", query_frequency = "15m" } }
  }
  expect_failures = [var.scheduled_rules]
}

run "rejects_unknown_tactic" {
  command = plan
  variables {
    scheduled_rules = { bad = { display_name = "x", severity = "Low", query = "x | take 1", tactics = ["Hacking"] } }
  }
  expect_failures = [var.scheduled_rules]
}

run "rejects_malformed_technique" {
  command = plan
  variables {
    scheduled_rules = { bad = { display_name = "x", severity = "Low", query = "x | take 1", techniques = ["1078"] } }
  }
  expect_failures = [var.scheduled_rules]
}

run "rejects_empty_query" {
  command = plan
  variables {
    scheduled_rules = { bad = { display_name = "x", severity = "Low", query = "  " } }
  }
  expect_failures = [var.scheduled_rules]
}

run "rejects_unstable_rule_key" {
  command = plan
  variables {
    scheduled_rules = { "Bad Key" = { display_name = "x", severity = "Low", query = "x | take 1" } }
  }
  expect_failures = [var.scheduled_rules]
}

run "rejects_unknown_entity_type" {
  command = plan
  variables {
    scheduled_rules = {
      bad = {
        display_name    = "x"
        severity        = "Low"
        query           = "x | take 1"
        entity_mappings = [{ entity_type = "Person", field_mappings = [{ identifier = "Name", column_name = "c" }] }]
      }
    }
  }
  expect_failures = [var.scheduled_rules]
}

run "rejects_more_than_five_nrt_entity_mappings" {
  command = plan
  variables {
    scheduled_rules = {}
    nrt_rules = {
      bad = {
        display_name = "x"
        severity     = "Low"
        query        = "x | take 1"
        entity_mappings = [for i in range(6) : {
          entity_type    = "Account"
          field_mappings = [{ identifier = "FullName", column_name = "c${i}" }]
        }]
      }
    }
  }
  expect_failures = [var.nrt_rules]
}

run "rejects_unknown_product_filter" {
  command = plan
  variables {
    scheduled_rules          = {}
    microsoft_incident_rules = { bad = { display_name = "x", product_filter = "Defender", severity_filter = ["High"] } }
  }
  expect_failures = [var.microsoft_incident_rules]
}

run "rejects_empty_severity_filter" {
  command = plan
  variables {
    scheduled_rules          = {}
    microsoft_incident_rules = { bad = { display_name = "x", product_filter = "Azure Security Center", severity_filter = [] } }
  }
  expect_failures = [var.microsoft_incident_rules]
}

run "rejects_template_guid_that_is_not_a_guid" {
  command = plan
  variables {
    scheduled_rules = {}
    template_rules  = { bad = { kind = "fusion", alert_rule_template = "Advanced Multistage Attack Detection" } }
  }
  expect_failures = [var.template_rules]
}

run "rejects_unknown_template_kind" {
  command = plan
  variables {
    scheduled_rules = {}
    template_rules  = { bad = { kind = "scheduled", alert_rule_template = "f71aba3d-28fb-450b-b192-4e76a83015c8" } }
  }
  expect_failures = [var.template_rules]
}

run "rejects_unknown_anomaly_mode" {
  command = plan
  variables {
    scheduled_rules = {}
    anomaly_rules   = { bad = { display_name = "x", mode = "Staging" } }
  }
  expect_failures = [var.anomaly_rules]
}
