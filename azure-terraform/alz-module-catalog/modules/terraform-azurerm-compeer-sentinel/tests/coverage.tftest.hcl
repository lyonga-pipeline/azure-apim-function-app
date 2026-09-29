mock_provider "azurerm" {}

variables {
  enabled                    = true
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mgmt/providers/Microsoft.OperationalInsights/workspaces/law"
}

run "all_four_data_connectors_can_be_enabled" {
  # None of these 4 resources had ever been exercised by a test.
  command = apply
  variables {
    data_connectors = {
      threat_intelligence = true
      defender_atp        = true
      entra_id            = true
      defender_for_cloud  = true
    }
  }

  assert {
    condition = (
      length(azurerm_sentinel_data_connector_threat_intelligence.threat_intel_connector) == 1 &&
      length(azurerm_sentinel_data_connector_microsoft_defender_advanced_threat_protection.mdatp_connector) == 1 &&
      length(azurerm_sentinel_data_connector_azure_active_directory.aad_connector) == 1 &&
      length(azurerm_sentinel_data_connector_azure_security_center.defender_connector) == 1
    )
    error_message = "all four data connectors should be created when their flag is true"
  }
}

run "data_connectors_off_by_default" {
  command = plan

  assert {
    condition = (
      length(azurerm_sentinel_data_connector_threat_intelligence.threat_intel_connector) == 0 &&
      length(azurerm_sentinel_data_connector_microsoft_defender_advanced_threat_protection.mdatp_connector) == 0 &&
      length(azurerm_sentinel_data_connector_azure_active_directory.aad_connector) == 0 &&
      length(azurerm_sentinel_data_connector_azure_security_center.defender_connector) == 0
    )
    error_message = "no data connector should be created when data_connectors is left at its default"
  }
}

run "include_default_rules_false_only_deploys_caller_rules" {
  # include_default_rules = true is implicit in every other test - the
  # false path (opt out of the two mandatory-by-default Palo Alto rules)
  # had never been exercised.
  command = apply
  variables {
    include_default_rules = false
    scheduled_alert_rules = {
      custom_rule = {
        display_name = "Custom rule"
        severity     = "Low"
        query        = "SigninLogs"
      }
    }
  }

  assert {
    condition     = length(azurerm_sentinel_alert_rule_scheduled.scheduled_rule) == 1
    error_message = "only the caller-supplied rule should exist when include_default_rules = false"
  }
  assert {
    condition     = !contains(keys(azurerm_sentinel_alert_rule_scheduled.scheduled_rule), "palo-alto-forwarding-stopped")
    error_message = "the mandatory Palo Alto forwarding-health rule must be excluded when opted out"
  }
}

run "create_incident_false_omits_the_incident_block" {
  command = apply
  variables {
    include_default_rules = false
    scheduled_alert_rules = {
      no_incident_rule = {
        display_name    = "No incident rule"
        severity        = "Informational"
        query           = "SigninLogs"
        create_incident = false
      }
    }
  }

  assert {
    condition     = length(azurerm_sentinel_alert_rule_scheduled.scheduled_rule["no_incident_rule"].incident) == 0
    error_message = "create_incident = false should omit the incident dynamic block entirely"
  }
}

run "scheduled_alert_rule_ids_maps_each_key_to_its_own_rule" {
  command = apply
  variables {
    include_default_rules = false
    scheduled_alert_rules = {
      rule_a = { display_name = "Rule A", severity = "High", query = "SigninLogs" }
      rule_b = { display_name = "Rule B", severity = "Low", query = "AuditLogs" }
    }
  }

  assert {
    condition = (
      output.scheduled_alert_rule_ids["rule_a"] == azurerm_sentinel_alert_rule_scheduled.scheduled_rule["rule_a"].id &&
      output.scheduled_alert_rule_ids["rule_b"] == azurerm_sentinel_alert_rule_scheduled.scheduled_rule["rule_b"].id
    )
    error_message = "scheduled_alert_rule_ids must map each key to its OWN rule's id, not a shared/mismatched one"
  }
}

run "data_connector_contract_output_is_wired" {
  command = apply
  variables {
    approved_data_connectors = {
      activity_log = { connector_type = "ActivityLog", enabled = true }
    }
  }

  assert {
    condition     = output.data_connector_contract != null
    error_message = "data_connector_contract output should reflect the approved_data_connectors contract"
  }
}
