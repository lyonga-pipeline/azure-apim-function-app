locals {
  workload_stem    = trimsuffix(module.naming.workload_vnet, "-spoke-vnet")
  action_group_ids = concat(tolist(var.operations.action_group_ids), [for group in module.alert_contacts : group.id])
}

module "alert_contacts" {
  source              = "../../modules/terraform-azurerm-compeer-actiongroup"
  count               = length(var.operations.notification_emails) > 0 ? 1 : 0
  name                = "${local.workload_stem}-operations-ag"
  short_name          = substr("${var.appcode}-${var.environment}", 0, 12)
  resource_group_name = module.resource_groups.group_names["operations"]
  receivers = { email = { for email in var.operations.notification_emails : email => {
    email_address = email, use_common_alert_schema = true
  } } }
  tags = module.tags.tags
}

module "application_insights" {
  source                                = "../../modules/terraform-azurerm-compeer-application-insights"
  name                                  = "${local.workload_stem}-appi"
  resource_group_name                   = module.resource_groups.group_names["operations"]
  location                              = var.location
  workspace_id                          = var.platform.log_analytics_workspace_id
  application_type                      = "other"
  sampling_percentage                   = local.environment_profile.telemetry_sampling_percentage
  retention_in_days                     = 90
  local_authentication_disabled         = true
  disable_ip_masking                    = false
  internet_ingestion_enabled            = var.monitoring.internet_ingestion_enabled
  internet_query_enabled                = var.monitoring.internet_query_enabled
  daily_data_cap_notifications_disabled = false
  tags                                  = module.tags.tags
}

module "telemetry_access" {
  source = "../../modules/terraform-azurerm-compeer-role-assignments"
  assignments = {
    workload = {
      scope                            = module.application_insights.id
      principal_id                     = module.workload_identity.principal_id
      principal_type                   = "ServicePrincipal"
      role_definition_name             = "Monitoring Metrics Publisher"
      skip_service_principal_aad_check = true
    }
  }
}

module "failed_requests_alert" {
  source              = "../../modules/terraform-azurerm-compeer-monitor-metric-alert"
  name                = "${local.workload_stem}-failed-requests"
  resource_group_name = module.resource_groups.group_names["operations"]
  scopes              = [module.application_insights.id]
  description         = "Application request failures exceeded the workload profile threshold; tune against the approved SLO."
  severity            = local.environment_profile.alert_severity
  frequency           = local.environment_profile.alert_frequency
  window_size         = "PT5M"
  criteria = {
    failed_requests = {
      metric_namespace = "Microsoft.Insights/components"
      metric_name      = "requests/failed"
      aggregation      = "Count"
      operator         = "GreaterThanOrEqual"
      threshold        = local.environment_profile.failed_request_threshold
    }
  }
  actions = { for index, id in local.action_group_ids : "recipient-${index}" => { action_group_id = id } }
  tags    = module.tags.tags
}

module "budget" {
  source          = "../../modules/terraform-azurerm-compeer-budget"
  scope_type      = "subscription"
  subscription_id = var.subscription_id
  budget_name     = "${local.workload_stem}-monthly-budget"
  amount          = var.operations.budget.amount
  start_date      = var.operations.budget.start_date
  notifications = {
    actual_80 = {
      threshold = 80, threshold_type = "Actual", contact_groups = local.action_group_ids
    }
    actual_100 = {
      threshold = 100, threshold_type = "Actual", contact_groups = local.action_group_ids
    }
    forecast_100 = {
      threshold = 100, threshold_type = "Forecasted", contact_groups = local.action_group_ids
    }
  }
}

resource "azurerm_backup_protected_vm" "workload" {
  for_each            = var.backup == null ? {} : var.backup.virtual_machines
  resource_group_name = try(split("/", var.backup.recovery_vault_id)[4], "")
  recovery_vault_name = try(split("/", var.backup.recovery_vault_id)[8], "")
  source_vm_id        = each.value
  backup_policy_id    = var.backup.backup_policy_id
  depends_on          = [terraform_data.capability_contract]
}
