mock_provider "azurerm" {}

variables {
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mgmt/providers/Microsoft.OperationalInsights/workspaces/law-platform"
  tenant_id                  = "11111111-1111-1111-1111-111111111111"
}

run "baseline_is_off_by_default" {
  command = plan

  assert {
    condition     = length(output.content_inventory.scheduled_rules) == 0
    error_message = "the SOC owns detection priorities: the baseline library must be opt-in"
  }
}

run "baseline_without_its_telemetry_fails_the_plan" {
  command = plan
  variables {
    baseline_content = { enabled = true }
  }
  expect_failures = [terraform_data.source_dependency_contract]
}

run "baseline_with_all_feeds_creates_five_rules" {
  command = apply
  variables {
    baseline_content            = { enabled = true }
    externally_provided_sources = ["azure_activity", "entra_audit_logs", "entra_signin_logs"]
  }

  assert {
    condition = (
      length(output.content_inventory.scheduled_rules) == 5 &&
      contains(output.content_inventory.scheduled_rules, "compeer-owner-role-assigned") &&
      length(azurerm_sentinel_alert_rule_scheduled.scheduled["compeer-pim-role-activation"].incident) == 0
    )
    error_message = "the five baseline rules must be created and the PIM volume signal must not open incidents"
  }
}

run "baseline_rules_can_be_excluded_individually" {
  command = plan
  variables {
    baseline_content = {
      enabled = true
      exclude = ["compeer-new-global-administrator", "compeer-pim-role-activation", "compeer-password-spray-suspected"]
    }
    externally_provided_sources = ["azure_activity"]
  }

  assert {
    condition     = length(output.content_inventory.scheduled_rules) == 2 && length(output.source_coverage.unmet) == 0
    error_message = "excluding the Entra rules must also drop their Entra telemetry requirement"
  }
}

run "caller_rules_coexist_with_the_baseline" {
  command = plan
  variables {
    baseline_content            = { enabled = true, exclude = ["compeer-new-global-administrator", "compeer-pim-role-activation", "compeer-password-spray-suspected"] }
    externally_provided_sources = ["azure_activity"]
    scheduled_rules = {
      soc-custom = { display_name = "SOC custom", severity = "Low", query = "AzureActivity | take 1", requires_sources = ["azure_activity"] }
    }
  }

  assert {
    condition     = length(output.content_inventory.scheduled_rules) == 3
    error_message = "caller rules must be added next to the baseline rules"
  }
}
