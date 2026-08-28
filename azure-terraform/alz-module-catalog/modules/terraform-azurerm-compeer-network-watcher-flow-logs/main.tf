resource "azurerm_network_watcher_flow_log" "this" {
  for_each = var.flow_logs

  name                      = each.value.name
  network_watcher_name      = each.value.network_watcher_name
  resource_group_name       = each.value.resource_group_name
  network_security_group_id = each.value.network_security_group_id
  storage_account_id        = each.value.storage_account_id
  enabled                   = try(each.value.enabled, true)

  retention_policy {
    enabled = coalesce(try(each.value.retention_policy.enabled, null), true)
    days    = coalesce(try(each.value.retention_policy.days, null), 90)
  }

  dynamic "traffic_analytics" {
    for_each = try(each.value.traffic_analytics, null) == null ? [] : [each.value.traffic_analytics]
    content {
      enabled               = try(traffic_analytics.value.enabled, true)
      workspace_id          = traffic_analytics.value.workspace_id
      workspace_region      = traffic_analytics.value.workspace_region
      workspace_resource_id = traffic_analytics.value.workspace_resource_id
      interval_in_minutes   = try(traffic_analytics.value.interval_in_minutes, 10)
    }
  }

  dynamic "timeouts" {
    for_each = length(try(each.value.timeouts, {})) == 0 ? [] : [each.value.timeouts]
    content {
      create = try(timeouts.value.create, null)
      read   = try(timeouts.value.read, null)
      update = try(timeouts.value.update, null)
      delete = try(timeouts.value.delete, null)
    }
  }
}
