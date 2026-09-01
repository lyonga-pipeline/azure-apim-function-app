# =============================================================================
# Platform baseline alerts (deploy-runbook.tf §2 gate: "alert routing
# validated"). A metric-alert set + Service Health activity-log alerts, all
# routed to the platform action group.
# =============================================================================

locals {
  pa_enabled      = coalesce(try(var.platform_alerts.enabled, null), false)
  pa_action_ids   = local.pa_enabled ? concat([module.action_group.id], try(var.platform_alerts.additional_action_group_ids, [])) : []
  pa_subscription = "/subscriptions/${var.subscription_id}"
}

module "platform_metric_alerts" {
  source   = "../../modules/terraform-azurerm-compeer-monitor-metric-alert"
  for_each = local.pa_enabled ? var.platform_alerts.metric_alerts : {}

  name                     = each.value.name
  resource_group_name      = module.resource_group.name
  scopes                   = each.value.scopes
  description              = try(each.value.description, null)
  severity                 = try(each.value.severity, 2)
  frequency                = try(each.value.frequency, "PT5M")
  window_size              = try(each.value.window_size, "PT15M")
  auto_mitigate            = try(each.value.auto_mitigate, true)
  target_resource_type     = try(each.value.target_resource_type, null)
  target_resource_location = try(each.value.target_resource_location, null)
  criteria                 = try(each.value.criteria, [])
  dynamic_criteria         = try(each.value.dynamic_criteria, [])
  actions                  = [for id in local.pa_action_ids : { action_group_id = id }]
  tags                     = module.tags.tags
}

# Azure Service Health (incident / maintenance / health advisory) for the
# platform subscription.
resource "azurerm_monitor_activity_log_alert" "service_health" {
  count = local.pa_enabled && coalesce(try(var.platform_alerts.service_health_enabled, null), true) ? 1 : 0

  name                = coalesce(try(var.platform_alerts.service_health_name, null), "alert-service-health")
  resource_group_name = module.resource_group.name
  location            = "global"
  scopes              = [local.pa_subscription]
  description         = "Azure Service Health events for the platform subscription."

  criteria {
    category = "ServiceHealth"

    service_health {
      events    = try(var.platform_alerts.service_health_events, ["Incident", "Maintenance", "Security"])
      locations = try(var.platform_alerts.service_health_locations, ["Global", var.location])
    }
  }

  dynamic "action" {
    for_each = toset(local.pa_action_ids)
    content {
      action_group_id = action.value
    }
  }

  tags = module.tags.tags
}
