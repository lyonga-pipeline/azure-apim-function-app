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
}
