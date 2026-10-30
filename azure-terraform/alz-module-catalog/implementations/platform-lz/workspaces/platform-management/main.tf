locals {
  enabled = try(var.management.enabled, false)

  # This workspace owns the deployment-lifecycle boundary for every resource
  # it creates, so it - not the tags module - owns created_on's stability.
  # time_static computes its value once, on first apply, and stores it in
  # state; every later plan reuses the same value instead of recomputing it
  # (unlike timestamp(), which would re-diff this tag on every single plan).
  # This intentionally supersedes any created_on set in platform_tags below.
  deployment_created_on = formatdate("YYYY-MM-DD", time_static.deployment_created.rfc3339)

}

resource "time_static" "deployment_created" {}

module "management" {
  source = "../../../../patterns/terraform-azurerm-compeer-platform-management"
  count  = local.enabled ? 1 : 0

  providers = {
    azurerm = azurerm
  }

  # Resource names come from the naming module inside the pattern - it is the
  # 'management' component. Only region + environment are supplied here; add a
  # `name` to a block in terraform.tfvars to override one.
  naming = {
    region             = var.location
    environment        = var.environment
    storage_uniqueness = var.subscription_id
  }

  subscription_id      = var.subscription_id
  location             = var.location
  environment          = var.environment
  platform_tags        = merge(var.platform_tags, try(var.management.platform_tags, {}), { created_on = local.deployment_created_on })
  resource_group       = try(var.management.resource_group, {})
  log_analytics        = try(var.management.log_analytics, null)
  log_analytics_tables = try(var.management.log_analytics_tables, {})
  action_group         = try(var.management.action_group, null)
  # PHASE2 NEW: v5 2.1 forwards the existing optional OBS-04 interface; empty default changes no deployed resources.
  platform_alerts                       = try(var.management.platform_alerts, {})
  platform_storage_accounts             = try(var.management.platform_storage_accounts, {})
  platform_storage_diagnostics          = try(var.management.platform_storage_diagnostics, {})
  data_collection_endpoints             = try(var.management.data_collection_endpoints, {})
  data_collection_rules                 = try(var.management.data_collection_rules, {})
  data_collection_rule_associations     = try(var.management.data_collection_rule_associations, {})
  sentinel                              = try(var.management.sentinel, { enabled = false })
  resource_provider_registrations       = try(var.management.resource_provider_registrations, {})
  role_assignments                      = try(var.management.role_assignments, {})
  subscription_activity_log_diagnostics = try(var.management.subscription_activity_log_diagnostics, null)
  entra_diagnostic_settings             = try(var.management.entra_diagnostic_settings, null)
  subscription_budgets                  = try(var.management.subscription_budgets, {})
  management_locks                      = try(var.management.management_locks, {})
  additional_lock_scopes                = try(var.management.additional_lock_scopes, {})
  defender_plans                        = try(var.management.defender_plans, {})
  security_contact                      = try(var.management.security_contact, null)
  security_center_settings              = try(var.management.security_center_settings, {})
  defender_soc_posture                  = try(var.management.defender_soc_posture, { enabled = false })
}

# =============================================================================
# PHASE 2 CHANGES - additive, opt-in; preserve existing resource/state ownership.
# Adopt this marked section with phase2_*.tf, phase2-tests/ and phase2.tfvars.example.
# =============================================================================

locals {
  phase2_observability_requested = length(var.phase2_log_alerts) + length(var.phase2_metric_alerts) + length(var.phase2_workbooks) > 0
  phase2_legacy_metric_names     = [for alert in values(try(var.management.platform_alerts.metric_alerts, {})) : lower(alert.name)]
}
resource "terraform_data" "phase2_observability_contract" {
  count = local.phase2_observability_requested ? 1 : 0
  lifecycle {
    precondition {
      condition     = local.enabled
      error_message = "Enable the existing management owner before adding Phase 2 monitoring; do not create a second LAW or action group."
    }
    precondition {
      condition     = length(setintersection(toset(local.phase2_legacy_metric_names), toset([for alert in values(var.phase2_metric_alerts) : lower(alert.name)]))) == 0
      error_message = "An existing management metric alert already owns this name. Extend its existing input rather than defining it again in Phase 2."
    }
  }
}
module "phase2_observability" {
  source                     = "../../../../patterns/terraform-azurerm-compeer-platform-observability"
  count                      = local.enabled && local.phase2_observability_requested ? 1 : 0
  resource_group_name        = module.management[0].resource_group_name
  location                   = var.location
  log_analytics_workspace_id = module.management[0].log_analytics_workspace_id
  action_group_ids           = setunion(toset(values(module.management[0].action_group_ids)), var.phase2_action_group_ids)
  log_alerts                 = var.phase2_log_alerts
  metric_alerts              = var.phase2_metric_alerts
  workbooks                  = var.phase2_workbooks
  # DCR/DCE definitions remain in management.*; VM extensions/associations stay with VM owners.
  agents              = {}
  connection_monitors = {}
  tags                = module.management[0].resource_tags
  depends_on          = [terraform_data.phase2_observability_contract]
}
