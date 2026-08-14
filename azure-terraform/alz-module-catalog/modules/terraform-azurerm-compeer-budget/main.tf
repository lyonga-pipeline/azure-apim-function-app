locals {
  budget_scope_type = var.scope_type != null ? var.scope_type : (
    var.create_for_management_group ? "management_group" : (
      var.create_for_subscription ? "subscription" : (
        var.create_for_rg ? "resource_group" : "resource_group"
      )
    )
  )

  budget_name       = var.budget_name != null ? var.budget_name : var.rg_budget_name
  budget_amount     = var.amount != null ? var.amount : var.rg_amount
  budget_start_date = var.start_date != null ? var.start_date : var.budget_start_date

  default_notifications = {
    default = {
      enabled        = true
      operator       = var.notification_operator
      threshold      = var.notification_threshold
      threshold_type = var.notification_threshold_type
      contact_emails = var.notification_contact_emails
      contact_groups = var.notification_contact_groups
      contact_roles  = var.notification_contact_roles
    }
  }

  notifications = length(var.notifications) > 0 ? var.notifications : local.default_notifications

  normalized_subscription_id = var.subscription_id == null ? null : (
    startswith(var.subscription_id, "/subscriptions/")
    ? var.subscription_id
    : "/subscriptions/${var.subscription_id}"
  )

  normalized_management_group_id = var.management_group_id == null ? null : (
    startswith(var.management_group_id, "/providers/Microsoft.Management/managementGroups/")
    ? var.management_group_id
    : "/providers/Microsoft.Management/managementGroups/${var.management_group_id}"
  )
}
