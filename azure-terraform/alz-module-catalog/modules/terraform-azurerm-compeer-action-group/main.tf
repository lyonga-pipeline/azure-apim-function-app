resource "azurerm_monitor_action_group" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  short_name          = var.short_name
  enabled             = var.enabled
  tags                = var.tags

  dynamic "email_receiver" {
    for_each = var.receivers.email
    content {
      name                    = email_receiver.key
      email_address           = email_receiver.value.email_address
      use_common_alert_schema = try(email_receiver.value.use_common_alert_schema, true)
    }
  }

  dynamic "webhook_receiver" {
    for_each = var.receivers.webhook
    content {
      name                    = webhook_receiver.key
      service_uri             = webhook_receiver.value.service_uri
      use_common_alert_schema = try(webhook_receiver.value.use_common_alert_schema, true)
    }
  }

  dynamic "sms_receiver" {
    for_each = var.receivers.sms
    content {
      name         = sms_receiver.key
      country_code = sms_receiver.value.country_code
      phone_number = sms_receiver.value.phone_number
    }
  }

  dynamic "voice_receiver" {
    for_each = var.receivers.voice
    content {
      name         = voice_receiver.key
      country_code = voice_receiver.value.country_code
      phone_number = voice_receiver.value.phone_number
    }
  }

  dynamic "arm_role_receiver" {
    for_each = var.receivers.arm_role
    content {
      name                    = arm_role_receiver.key
      role_id                 = arm_role_receiver.value.role_id
      use_common_alert_schema = try(arm_role_receiver.value.use_common_alert_schema, true)
    }
  }

  dynamic "automation_runbook_receiver" {
    for_each = try(var.receivers.automation_runbook, {})
    content {
      name                    = automation_runbook_receiver.key
      automation_account_id   = automation_runbook_receiver.value.automation_account_id
      runbook_name            = automation_runbook_receiver.value.runbook_name
      webhook_resource_id     = automation_runbook_receiver.value.webhook_resource_id
      is_global_runbook       = automation_runbook_receiver.value.is_global_runbook
      service_uri             = automation_runbook_receiver.value.service_uri
      use_common_alert_schema = try(automation_runbook_receiver.value.use_common_alert_schema, true)
    }
  }

  dynamic "azure_app_push_receiver" {
    for_each = try(var.receivers.azure_app_push, {})
    content {
      name          = azure_app_push_receiver.key
      email_address = azure_app_push_receiver.value.email_address
    }
  }

  dynamic "azure_function_receiver" {
    for_each = try(var.receivers.azure_function, {})
    content {
      name                     = azure_function_receiver.key
      function_app_resource_id = azure_function_receiver.value.function_app_resource_id
      function_name            = azure_function_receiver.value.function_name
      http_trigger_url         = azure_function_receiver.value.http_trigger_url
      use_common_alert_schema  = try(azure_function_receiver.value.use_common_alert_schema, true)
    }
  }

  dynamic "event_hub_receiver" {
    for_each = try(var.receivers.event_hub, {})
    content {
      name                    = event_hub_receiver.key
      event_hub_name          = event_hub_receiver.value.event_hub_name
      event_hub_namespace     = event_hub_receiver.value.event_hub_namespace
      subscription_id         = event_hub_receiver.value.subscription_id
      tenant_id               = try(event_hub_receiver.value.tenant_id, null)
      use_common_alert_schema = try(event_hub_receiver.value.use_common_alert_schema, true)
    }
  }

  dynamic "itsm_receiver" {
    for_each = try(var.receivers.itsm, {})
    content {
      name                 = itsm_receiver.key
      workspace_id         = itsm_receiver.value.workspace_id
      connection_id        = itsm_receiver.value.connection_id
      ticket_configuration = itsm_receiver.value.ticket_configuration
      region               = itsm_receiver.value.region
    }
  }

  dynamic "logic_app_receiver" {
    for_each = try(var.receivers.logic_app, {})
    content {
      name                    = logic_app_receiver.key
      resource_id             = logic_app_receiver.value.resource_id
      callback_url            = logic_app_receiver.value.callback_url
      use_common_alert_schema = try(logic_app_receiver.value.use_common_alert_schema, true)
    }
  }

  timeouts {
    create = try(var.timeouts.create, null)
    update = try(var.timeouts.update, null)
    read   = try(var.timeouts.read, null)
    delete = try(var.timeouts.delete, null)
  }
}
