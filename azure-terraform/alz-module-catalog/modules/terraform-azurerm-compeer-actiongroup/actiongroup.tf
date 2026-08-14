resource "azurerm_monitor_action_group" "this" {
  name                = var.action_group_name
  resource_group_name = var.resource_group_name
  short_name          = var.action_group_short_name

  dynamic "email_receiver" {
    for_each = var.actiongrp_email_receiver
    content {
      name                    = each.value.name
      email_address           = each.value.email_address
      use_common_alert_schema = try(each.value.use_common_alert_schema, true)
    }
  }

  dynamic "automation_runbook_receiver" {
    for_each = var.actiongrp_automation_runbook_receiver
    content {
      name                    = each.value.name
      automation_account_id   = each.value.automation_account_id
      runbook_name            = each.value.runbook_name
      webhook_resource_id     = each.value.webhook_resource_id
      is_global_runbook       = each.value.is_global_runbook
      service_uri             = each.value.service_uri
      use_common_alert_schema = try(each.value.use_common_alert_schema, true)
    }
  }
}