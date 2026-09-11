locals {
  break_glass_principal_list = join(", ", [
    for principal in var.break_glass_user_principal_names : format("'%s'", replace(principal, "'", "''"))
  ])
}

resource "azurerm_pim_eligible_role_assignment" "this" {
  for_each = var.pim_eligible_role_assignments

  scope              = each.value.scope
  role_definition_id = each.value.role_definition_id
  principal_id       = each.value.principal_id
  justification      = try(each.value.justification, null)
  condition          = try(each.value.condition, null)
  condition_version  = try(each.value.condition_version, null)

  dynamic "schedule" {
    for_each = try(each.value.schedule, null) == null ? [] : [each.value.schedule]
    content {
      start_date_time = try(schedule.value.start_date_time, null)

      dynamic "expiration" {
        for_each = try(schedule.value.expiration, null) == null ? [] : [schedule.value.expiration]
        content {
          duration_days  = try(expiration.value.duration_days, null)
          duration_hours = try(expiration.value.duration_hours, null)
          end_date_time  = try(expiration.value.end_date_time, null)
        }
      }
    }
  }

  dynamic "ticket" {
    for_each = try(each.value.ticket, null) == null ? [] : [each.value.ticket]
    content {
      number = try(ticket.value.number, null)
      system = try(ticket.value.system, null)
    }
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "break_glass_signin" {
  count = var.break_glass_alert.enabled && length(var.break_glass_user_principal_names) > 0 ? 1 : 0

  name                    = var.break_glass_alert.name
  display_name            = try(var.break_glass_alert.display_name, var.break_glass_alert.name)
  resource_group_name     = var.break_glass_alert.resource_group_name
  location                = var.break_glass_alert.location
  scopes                  = [var.log_analytics_workspace_id]
  description             = "Alert on any sign-in by a cloud-only break-glass account."
  severity                = try(var.break_glass_alert.severity, 0)
  enabled                 = true
  evaluation_frequency    = try(var.break_glass_alert.evaluation_frequency, "PT5M")
  window_duration         = try(var.break_glass_alert.window_duration, "PT5M")
  auto_mitigation_enabled = true
  skip_query_validation   = try(var.break_glass_alert.skip_query_validation, true)
  tags                    = var.tags

  criteria {
    query                   = <<-KQL
      SigninLogs
      | where UserPrincipalName in~ (${local.break_glass_principal_list})
      | summarize SignInCount = count() by UserPrincipalName, bin(TimeGenerated, 5m)
    KQL
    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  dynamic "action" {
    for_each = length(try(var.break_glass_alert.action_group_ids, [])) == 0 ? [] : [var.break_glass_alert.action_group_ids]
    content {
      action_groups = action.value
    }
  }

  lifecycle {
    precondition {
      condition     = var.log_analytics_workspace_id != null
      error_message = "log_analytics_workspace_id is required when break_glass_alert.enabled is true."
    }
    precondition {
      condition     = try(var.break_glass_alert.resource_group_name, null) != null
      error_message = "break_glass_alert.resource_group_name is required when break_glass_alert.enabled is true."
    }
  }
}

module "role_management_policies" {
  source = "../../modules/terraform-azurerm-compeer-role-management-policy"

  policies = var.role_management_policies
}

module "operational_contracts" {
  source = "../../modules/terraform-azurerm-compeer-operational-contracts"

  contracts = var.operational_contracts
}
