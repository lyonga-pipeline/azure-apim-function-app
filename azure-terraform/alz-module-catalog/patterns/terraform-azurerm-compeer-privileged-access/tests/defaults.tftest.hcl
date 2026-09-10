mock_provider "azurerm" {}

run "empty_is_noop" {
  command = plan
  assert {
    condition     = length(azurerm_pim_eligible_role_assignment.this) == 0
    error_message = "no eligible assignments by default"
  }
  assert {
    condition     = length(azurerm_monitor_scheduled_query_rules_alert_v2.break_glass_signin) == 0
    error_message = "break-glass alert is off by default"
  }
}

run "eligible_assignments" {
  command = plan
  variables {
    pim_eligible_role_assignments = {
      plt_admins_owner = {
        scope              = "/providers/Microsoft.Management/managementGroups/platform-mg"
        role_definition_id = "/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635"
        principal_id       = "11111111-1111-1111-1111-111111111111"
        justification      = "Platform admin standing eligibility."
        schedule = {
          expiration = { duration_days = 365 }
        }
      }
    }
  }
  assert {
    condition     = length(azurerm_pim_eligible_role_assignment.this) == 1
    error_message = "expected one eligible assignment"
  }
}

run "break_glass_alert_requires_workspace" {
  command = plan
  variables {
    break_glass_user_principal_names = ["emergency-01@compeer.example", "emergency-02@compeer.example"]
    break_glass_alert = {
      enabled             = true
      resource_group_name = "rg-secops-alerts"
    }
  }
  expect_failures = [azurerm_monitor_scheduled_query_rules_alert_v2.break_glass_signin]
}

run "break_glass_alert_enabled" {
  command = plan
  variables {
    log_analytics_workspace_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-law/providers/Microsoft.OperationalInsights/workspaces/law-compeer-prod"
    break_glass_user_principal_names = ["emergency-01@compeer.example", "emergency-02@compeer.example"]
    break_glass_alert = {
      enabled             = true
      resource_group_name = "rg-secops-alerts"
      action_group_ids    = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-secops-alerts/providers/Microsoft.Insights/actionGroups/soc-critical"]
    }
  }
  assert {
    condition     = length(azurerm_monitor_scheduled_query_rules_alert_v2.break_glass_signin) == 1
    error_message = "alert should be created when enabled with a workspace + RG"
  }
}

run "operational_contracts_surface" {
  command = apply
  variables {
    operational_contracts = {
      pim_activation_policy = {
        implementation_state = "provider-gap"
        required_controls    = ["approval", "MFA on activation", "max 8h duration", "notifications"]
        notes                = "Eligible assignments are codified here; activation-policy settings reconciled in the portal."
      }
      admin_conditional_access = {
        implementation_state = "manual-control"
        notes                = "Tenant-wide, high lockout risk."
      }
    }
  }
  assert {
    condition     = length(output.manual_control_keys) == 2
    error_message = "both contracts should be reported as non-codified"
  }
}
