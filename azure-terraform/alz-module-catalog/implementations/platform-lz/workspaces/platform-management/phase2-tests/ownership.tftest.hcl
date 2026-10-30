# =============================================================================
# PHASE 2 CHANGES - additive, opt-in; preserve existing resource/state ownership.
# Copy this file together with the PHASE 2 section in main.tf and the example.
# =============================================================================
mock_provider "azurerm" {}
mock_provider "time" {}
mock_provider "tfe" {}
variables {
  tenant_id       = "00000000-0000-0000-0000-000000000000"
  subscription_id = "11111111-1111-1111-1111-111111111111"

  management = {
    enabled       = true
    log_analytics = {}
    action_group  = { short_name = "platops" }
    sentinel      = { enabled = false }
  }
}
run "phase2_off_preserves_existing_management_owner" {
  command = plan
  variables {
    phase2_log_alerts    = {}
    phase2_metric_alerts = {}
    phase2_workbooks     = {}
  }
  assert {
    condition     = length(module.management) == 1 && length(module.phase2_observability) == 0
    error_message = "Existing management remains the owner; Phase 2 is inert by default."
  }
}
run "phase2_pilot_reuses_management_law_action_group_and_tags" {
  command = plan
  assert {
    condition     = length(module.management) == 1 && length(module.phase2_observability[0].log_alert_ids) == 3 && length(module.phase2_observability[0].metric_alert_ids) == 3 && length(module.phase2_observability[0].workbook_ids) == 1 && length(module.phase2_observability[0].agent_ids) == 0 && length(module.phase2_observability[0].connection_monitor_ids) == 0
    error_message = "Only alert/workbook capabilities belong in this management extension; VM/network resources stay elsewhere."
  }
}
run "existing_metric_alert_cannot_get_a_second_owner" {
  command = plan
  variables {
    management = {
      enabled = true, log_analytics = {}, action_group = { short_name = "platops" }
      platform_alerts = { enabled = true, service_health_enabled = false, metric_alerts = { existing = {
        name     = "law-export-failed"
        scopes   = ["/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.OperationalInsights/workspaces/central-law"]
        criteria = { export = { metric_namespace = "Microsoft.OperationalInsights/workspaces", metric_name = "ExportFailed", aggregation = "Total", operator = "GreaterThan", threshold = 0 } }
      } } }
    }
  }
  expect_failures = [terraform_data.phase2_observability_contract]
}
