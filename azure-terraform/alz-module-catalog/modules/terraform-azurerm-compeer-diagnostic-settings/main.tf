resource "azurerm_monitor_diagnostic_setting" "this" {
  name                           = var.name
  target_resource_id             = var.target_resource_id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  log_analytics_destination_type = var.log_analytics_destination_type
  storage_account_id             = var.storage_account_id
  eventhub_authorization_rule_id = var.eventhub_authorization_rule_id
  eventhub_name                  = var.eventhub_name
  partner_solution_id            = var.partner_solution_id

  dynamic "enabled_log" {
    for_each = var.logs
    content {
      category       = try(enabled_log.value.category, null)
      category_group = try(enabled_log.value.category_group, null)
    }
  }

  dynamic "enabled_metric" {
    for_each = {
      for key, metric in var.metrics : key => metric
      if try(metric.enabled, true)
    }
    content {
      category = enabled_metric.value.category
    }
  }

  lifecycle {
    precondition {
      condition = (
        var.log_analytics_workspace_id != null ||
        var.storage_account_id != null ||
        var.eventhub_authorization_rule_id != null ||
        var.partner_solution_id != null
      )
      error_message = "At least one diagnostic destination must be set."
    }
  }

  timeouts {
    create = try(var.timeouts.create, null)
    update = try(var.timeouts.update, null)
    read   = try(var.timeouts.read, null)
    delete = try(var.timeouts.delete, null)
  }
}
