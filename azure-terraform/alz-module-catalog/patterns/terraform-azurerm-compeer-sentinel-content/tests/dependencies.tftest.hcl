mock_provider "azurerm" {}

# A rule that reads a table nothing feeds must stop the plan, and say which
# rule and which source. This is the first-deployment failure mode the
# contract exists for.

variables {
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mgmt/providers/Microsoft.OperationalInsights/workspaces/law-platform"
  tenant_id                  = "11111111-1111-1111-1111-111111111111"
  scheduled_rules = {
    signin-spray = {
      display_name     = "Spray"
      severity         = "Medium"
      query            = "SigninLogs | take 1"
      requires_sources = ["entra_signin_logs"]
    }
  }
}

run "rule_without_its_source_fails_the_plan" {
  command         = plan
  expect_failures = [terraform_data.source_dependency_contract]
}

run "declaring_the_external_feed_allows_the_rule" {
  command = plan
  variables {
    externally_provided_sources = ["entra_signin_logs"]
  }

  assert {
    condition     = length(output.source_coverage.unmet) == 0
    error_message = "a rule whose source is declared external must be allowed"
  }
}

run "a_disabled_rule_does_not_need_its_source" {
  command = plan
  variables {
    scheduled_rules = {
      signin-spray = {
        display_name     = "Spray"
        severity         = "Medium"
        query            = "SigninLogs | take 1"
        enabled          = false
        requires_sources = ["entra_signin_logs"]
      }
    }
  }

  assert {
    condition     = length(output.source_coverage.unmet) == 0
    error_message = "a disabled rule must not demand telemetry"
  }
}

run "an_enabled_connector_satisfies_security_alert_rules" {
  command = plan
  variables {
    scheduled_rules = {}
    data_connectors = { defender_for_cloud = { default = {} } }
    microsoft_incident_rules = {
      dfc = { display_name = "DfC", product_filter = "Azure Security Center", severity_filter = ["High"] }
    }
  }

  assert {
    condition     = length(output.source_coverage.unmet) == 0
    error_message = "the default security_alert requirement must be met by an enabled alert connector"
  }
}

run "an_incident_rule_without_a_connector_fails_the_plan" {
  command = plan
  variables {
    scheduled_rules = {}
    microsoft_incident_rules = {
      dfc = { display_name = "DfC", product_filter = "Azure Security Center", severity_filter = ["High"] }
    }
  }
  expect_failures = [terraform_data.source_dependency_contract]
}

run "enforcement_can_be_switched_off_for_a_staged_rollout" {
  command = plan
  variables {
    enforce_source_dependencies = false
  }

  assert {
    condition     = length(output.source_coverage.unmet) == 1
    error_message = "with enforcement off the gap must still be reported in source_coverage"
  }
}
