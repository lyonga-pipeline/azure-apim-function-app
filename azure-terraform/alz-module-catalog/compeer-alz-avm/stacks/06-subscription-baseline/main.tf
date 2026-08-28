locals {
  subscription_scope = "/subscriptions/${var.subscription_id}"
  tags = merge({
    Environment = var.environment
    ManagedBy   = "Terraform"
    IaCSource   = "CompeerHCP"
    LandingZone = "CentralUS"
  }, var.tags)
}

resource "azurerm_resource_provider_registration" "this" {
  for_each = var.resource_provider_registrations

  name = each.key
}

module "resource_groups" {
  for_each = var.resource_groups
  source   = "app.terraform.io/Compeer-Financial-Services/compeer-resource-group/azurerm"
  version  = "1.0.0"

  name     = each.value.name
  location = coalesce(try(each.value.location, null), var.location)
  tags     = merge(local.tags, try(each.value.tags, {}))
}

module "subscription_activity_log" {
  count   = var.log_analytics_workspace_id == null ? 0 : 1
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-diagnostic-settings/azurerm"
  version = "1.0.0"

  name                       = "${var.prefix}-${var.environment}-subscription-activity-law"
  target_resource_id         = local.subscription_scope
  log_analytics_workspace_id = var.log_analytics_workspace_id
  logs = {
    for category in var.activity_log_categories : lower(category) => {
      category = category
    }
  }
}

module "role_assignments" {
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-role-assignments/azurerm"
  version = "1.0.0"

  assignments = var.role_assignments
}

module "policy_baseline" {
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-policy-baseline/azurerm"
  version = "1.0.0"

  policy_definitions         = var.policy_definitions
  policy_set_definitions     = var.policy_set_definitions
  subscription_assignments   = var.subscription_policy_assignments
  resource_group_assignments = var.resource_group_policy_assignments
  exemptions                 = var.policy_exemptions
}

module "defender_soc_posture" {
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-defender-soc-posture/azurerm"
  version = "1.0.0"

  enabled                  = var.defender_enabled
  defender_plans           = var.defender_plans
  security_contact         = var.security_contact
  security_center_settings = var.security_center_settings
  posture_contract         = var.soc_posture_contract
}

resource "azurerm_consumption_budget_subscription" "budget" {
  for_each = var.budgets

  name            = each.value.name
  subscription_id = local.subscription_scope
  amount          = each.value.amount
  time_grain      = try(each.value.time_grain, "Monthly")

  time_period {
    start_date = each.value.start_date
    end_date   = try(each.value.end_date, null)
  }

  dynamic "notification" {
    for_each = each.value.notifications

    content {
      enabled        = try(notification.value.enabled, true)
      operator       = try(notification.value.operator, "GreaterThanOrEqualTo")
      threshold      = notification.value.threshold
      threshold_type = try(notification.value.threshold_type, "Actual")
      contact_emails = try(notification.value.contact_emails, [])
      contact_groups = try(notification.value.contact_groups, [])
      contact_roles  = try(notification.value.contact_roles, [])
    }
  }
}

module "operational_contracts" {
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-operational-contracts/azurerm"
  version = "1.0.0"

  contracts = var.operational_contracts
}
