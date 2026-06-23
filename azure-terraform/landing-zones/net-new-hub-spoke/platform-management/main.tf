module "tags" {
  source = "../../../modules/platform-tags"

  environment         = var.environment
  application         = var.platform_tags.application
  business_owner      = var.platform_tags.business_owner
  source_repo         = var.platform_tags.source_repo
  terraform_workspace = var.platform_tags.terraform_workspace
  recovery_tier       = var.platform_tags.recovery_tier
  cost_center         = var.platform_tags.cost_center
  data_classification = var.platform_tags.data_classification
  compliance_boundary = var.platform_tags.compliance_boundary
  additional_tags     = var.platform_tags.additional_tags
}

module "resource_group" {
  source = "../../../modules/resource-group"

  name     = var.resource_group.name
  location = var.location
  tags     = module.tags.tags
}

module "log_analytics" {
  source = "../../../modules/log-analytics"

  name                = var.log_analytics.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  retention_in_days   = var.log_analytics.retention_in_days
  daily_quota_gb      = try(var.log_analytics.daily_quota_gb, null)
  tags                = module.tags.tags
}

module "action_group" {
  source = "../../../modules/action-group"

  name                = var.action_group.name
  resource_group_name = module.resource_group.name
  short_name          = var.action_group.short_name
  receivers           = var.action_group.receivers
  tags                = module.tags.tags
}

locals {
  subscription_scope = "/subscriptions/${var.subscription_id}"
  platform_scope_ids = merge(
    {
      subscription   = local.subscription_scope
      resource_group = module.resource_group.id
      log_analytics  = module.log_analytics.id
      action_group   = module.action_group.id
    },
    var.additional_lock_scopes
  )

  role_assignment_inputs = {
    for key, assignment in var.role_assignments : key => merge(assignment, {
      scope = coalesce(
        try(assignment.scope, null),
        try(local.platform_scope_ids[assignment.scope_key], null)
      )
    })
  }
}

resource "azurerm_resource_provider_registration" "this" {
  for_each = var.resource_provider_registrations

  name = each.key

  dynamic "feature" {
    for_each = try(each.value.features, {})
    content {
      name       = feature.key
      registered = feature.value.registered
    }
  }
}

module "role_assignments" {
  source = "../../../modules/role-assignments"

  assignments = local.role_assignment_inputs
}

resource "azurerm_monitor_diagnostic_setting" "subscription_activity_log" {
  count = var.subscription_activity_log_diagnostics == null ? 0 : 1

  name                       = var.subscription_activity_log_diagnostics.name
  target_resource_id         = local.subscription_scope
  log_analytics_workspace_id = module.log_analytics.id
  storage_account_id         = try(var.subscription_activity_log_diagnostics.storage_account_id, null)
  eventhub_authorization_rule_id = try(
    var.subscription_activity_log_diagnostics.eventhub_authorization_rule_id,
    null
  )
  eventhub_name = try(var.subscription_activity_log_diagnostics.eventhub_name, null)

  dynamic "enabled_log" {
    for_each = var.subscription_activity_log_diagnostics.logs
    content {
      category = enabled_log.value.category
    }
  }
}

resource "azurerm_monitor_aad_diagnostic_setting" "entra" {
  count = var.entra_diagnostic_settings == null ? 0 : 1

  name                           = var.entra_diagnostic_settings.name
  log_analytics_workspace_id     = module.log_analytics.id
  storage_account_id             = try(var.entra_diagnostic_settings.storage_account_id, null)
  eventhub_authorization_rule_id = try(var.entra_diagnostic_settings.eventhub_authorization_rule_id, null)
  eventhub_name                  = try(var.entra_diagnostic_settings.eventhub_name, null)

  dynamic "enabled_log" {
    for_each = var.entra_diagnostic_settings.logs
    content {
      category = enabled_log.value.category
    }
  }
}

resource "azurerm_consumption_budget_subscription" "this" {
  for_each = var.subscription_budgets

  name            = each.key
  subscription_id = local.subscription_scope
  amount          = each.value.amount
  time_grain      = each.value.time_grain

  time_period {
    start_date = each.value.time_period.start_date
    end_date   = try(each.value.time_period.end_date, null)
  }

  dynamic "notification" {
    for_each = each.value.notifications
    content {
      enabled        = try(notification.value.enabled, true)
      threshold      = notification.value.threshold
      operator       = notification.value.operator
      threshold_type = try(notification.value.threshold_type, "Actual")
      contact_emails = try(notification.value.contact_emails, null)
      contact_groups = try(notification.value.contact_groups, null)
      contact_roles  = try(notification.value.contact_roles, null)
    }
  }
}

resource "azurerm_management_lock" "this" {
  for_each = var.management_locks

  name       = each.value.name
  scope      = coalesce(try(each.value.scope, null), try(local.platform_scope_ids[each.value.scope_key], null))
  lock_level = each.value.lock_level
  notes      = try(each.value.notes, null)
}

resource "azurerm_security_center_subscription_pricing" "this" {
  for_each = var.defender_plans

  resource_type = each.value.resource_type
  tier          = each.value.tier
  subplan       = try(each.value.subplan, null)

  dynamic "extension" {
    for_each = try(each.value.extensions, {})
    content {
      name                            = extension.value.name
      additional_extension_properties = try(extension.value.additional_extension_properties, null)
    }
  }
}

resource "azurerm_security_center_contact" "this" {
  count = var.security_contact == null ? 0 : 1

  name                = try(var.security_contact.name, "default")
  email               = var.security_contact.email
  phone               = try(var.security_contact.phone, null)
  alert_notifications = try(var.security_contact.alert_notifications, true)
  alerts_to_admins    = try(var.security_contact.alerts_to_admins, true)
}

resource "azurerm_security_center_setting" "this" {
  for_each = var.security_center_settings

  setting_name = each.key
  enabled      = each.value.enabled
}
