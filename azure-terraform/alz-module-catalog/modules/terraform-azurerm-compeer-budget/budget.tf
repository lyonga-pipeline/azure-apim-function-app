resource "azurerm_consumption_budget_resource_group" "this" {
  count = local.budget_scope_type == "resource_group" ? 1 : 0

  name              = local.budget_name
  resource_group_id = data.azurerm_resource_group.this[0].id
  amount            = local.budget_amount
  time_grain        = var.time_grain

  time_period {
    start_date = local.budget_start_date
    end_date   = var.end_date
  }

  dynamic "notification" {
    for_each = local.notifications

    content {
      enabled        = notification.value.enabled
      operator       = notification.value.operator
      threshold      = notification.value.threshold
      threshold_type = notification.value.threshold_type
      contact_emails = notification.value.contact_emails
      contact_groups = notification.value.contact_groups
      contact_roles  = notification.value.contact_roles
    }
  }

  lifecycle {
    precondition {
      condition     = var.resource_group_name != null && local.budget_name != null && local.budget_amount != null && local.budget_start_date != null
      error_message = "Resource group budgets require resource_group_name, budget_name or rg_budget_name, amount or rg_amount, and start_date or budget_start_date."
    }
  }
}

resource "azurerm_consumption_budget_subscription" "this" {
  count = local.budget_scope_type == "subscription" ? 1 : 0

  name            = local.budget_name
  subscription_id = local.normalized_subscription_id
  amount          = local.budget_amount
  time_grain      = var.time_grain

  time_period {
    start_date = local.budget_start_date
    end_date   = var.end_date
  }

  dynamic "notification" {
    for_each = local.notifications

    content {
      enabled        = notification.value.enabled
      operator       = notification.value.operator
      threshold      = notification.value.threshold
      threshold_type = notification.value.threshold_type
      contact_emails = notification.value.contact_emails
      contact_groups = notification.value.contact_groups
      contact_roles  = notification.value.contact_roles
    }
  }

  lifecycle {
    precondition {
      condition     = local.normalized_subscription_id != null && local.budget_name != null && local.budget_amount != null && local.budget_start_date != null
      error_message = "Subscription budgets require subscription_id, budget_name or rg_budget_name, amount or rg_amount, and start_date or budget_start_date."
    }
  }
}

resource "azurerm_consumption_budget_management_group" "this" {
  count = local.budget_scope_type == "management_group" ? 1 : 0

  name                = local.budget_name
  management_group_id = local.normalized_management_group_id
  amount              = local.budget_amount
  time_grain          = var.time_grain

  time_period {
    start_date = local.budget_start_date
    end_date   = var.end_date
  }

  dynamic "notification" {
    for_each = local.notifications

    content {
      enabled        = notification.value.enabled
      operator       = notification.value.operator
      threshold      = notification.value.threshold
      threshold_type = notification.value.threshold_type
      contact_emails = notification.value.contact_emails
      contact_groups = notification.value.contact_groups
      contact_roles  = notification.value.contact_roles
    }
  }

  lifecycle {
    precondition {
      condition     = local.normalized_management_group_id != null && local.budget_name != null && local.budget_amount != null && local.budget_start_date != null
      error_message = "Management group budgets require management_group_id, budget_name or rg_budget_name, amount or rg_amount, and start_date or budget_start_date."
    }
  }
}
