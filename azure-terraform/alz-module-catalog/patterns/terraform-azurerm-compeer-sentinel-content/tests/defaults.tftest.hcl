mock_provider "azurerm" {}

variables {
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mgmt/providers/Microsoft.OperationalInsights/workspaces/law-platform"
  tenant_id                  = "11111111-1111-1111-1111-111111111111"
}

run "defaults_create_nothing" {
  command = apply

  assert {
    condition = (
      length(output.analytics_rule_ids) == 0 &&
      length(output.connector_ids) == 0 &&
      length(output.automation_rule_ids) == 0 &&
      length(output.watchlist_ids) == 0 &&
      output.onboarding_id == null
    )
    error_message = "with no inputs the pattern must create no Sentinel content and must not onboard the workspace"
  }
  assert {
    condition     = output.workspace_id == var.log_analytics_workspace_id && output.content_inventory.baseline_enabled == false
    error_message = "the workspace ID must pass through and the baseline library must be off by default"
  }
}

run "onboarding_is_opt_in" {
  command = apply
  variables {
    manage_onboarding = true
  }

  assert {
    condition     = output.onboarding_id != null
    error_message = "manage_onboarding = true must create the onboarding"
  }
}

run "rejects_malformed_workspace_id" {
  command = plan
  variables {
    log_analytics_workspace_id = "law-platform"
  }
  expect_failures = [var.log_analytics_workspace_id]
}

run "rejects_malformed_tenant_id" {
  command = plan
  variables {
    tenant_id = "not-a-uuid"
  }
  expect_failures = [var.tenant_id]
}

run "rejects_unknown_external_source" {
  command = plan
  variables {
    externally_provided_sources = ["azure_activty"]
  }
  expect_failures = [var.externally_provided_sources]
}
