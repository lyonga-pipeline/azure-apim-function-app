# PHASE2 NEW: audit-only rollout. DoNotEnforce prevents inherited Deny/Modify/DINE effects from blocking or mutating resources.
resource "azurerm_management_group_policy_assignment" "audit" {
  for_each             = var.audit_initiatives
  name                 = each.value.name
  management_group_id  = each.value.management_group_id
  policy_definition_id = each.value.policy_set_definition_id
  parameters           = each.value.parameters_json
  enforce              = false
  metadata             = jsonencode({ phase = 2, approval = each.value.approval_reference, owner = "platform-governance" })
}
module "exemptions" {
  source = "../../modules/terraform-azurerm-compeer-policy"
  exemptions = { for key, exemption in var.exemptions : exemption.name => {
    scope_type                      = exemption.scope_type
    subscription_id                 = exemption.scope_type == "subscription" ? exemption.scope_id : null
    resource_group_id               = exemption.scope_type == "resource_group" ? exemption.scope_id : null
    policy_assignment_id            = exemption.policy_assignment_id
    exemption_category              = exemption.category
    description                     = exemption.justification
    expires_on                      = exemption.expires_on
    policy_definition_reference_ids = exemption.policy_definition_reference_ids
    metadata                        = { approved_by = exemption.approved_by, ticket = exemption.ticket }
  } if exemption.scope_type != "resource" }
  depends_on = [terraform_data.expiry]
}
resource "azurerm_resource_policy_exemption" "resource" {
  for_each                        = { for key, value in var.exemptions : key => value if value.scope_type == "resource" }
  name                            = each.value.name
  resource_id                     = each.value.scope_id
  policy_assignment_id            = each.value.policy_assignment_id
  exemption_category              = each.value.category
  description                     = each.value.justification
  expires_on                      = each.value.expires_on
  policy_definition_reference_ids = each.value.policy_definition_reference_ids
  metadata                        = jsonencode({ approved_by = each.value.approved_by, ticket = each.value.ticket })
  depends_on                      = [terraform_data.expiry]
}
resource "terraform_data" "expiry" {
  for_each = var.exemptions
  lifecycle {
    precondition {
      condition     = try(timecmp(each.value.expires_on, plantimestamp()) > 0, false)
      error_message = "A new/renewed exemption must expire in the future; expired waivers must not be silently reactivated."
    }
  }
}
resource "azurerm_consumption_budget_subscription" "subscription" {
  for_each        = var.budgets
  name            = each.value.name
  subscription_id = "/subscriptions/${var.subscription_id}"
  amount          = each.value.amount
  time_grain      = "Monthly"
  time_period {
    start_date = each.value.start_date
    end_date   = each.value.end_date
  }
  dynamic "notification" {
    for_each = { actual80 = { threshold = 80, type = "Actual" }, actual100 = { threshold = 100, type = "Actual" }, forecast100 = { threshold = 100, type = "Forecasted" } }
    content {
      enabled        = true
      threshold      = notification.value.threshold
      threshold_type = notification.value.type
      operator       = "GreaterThanOrEqualTo"
      contact_emails = each.value.contact_emails
      contact_groups = each.value.contact_groups
    }
  }
}
resource "azurerm_subscription_cost_management_export" "cost" {
  for_each                     = var.cost_exports
  name                         = each.value.name
  subscription_id              = "/subscriptions/${var.subscription_id}"
  recurrence_type              = "Daily"
  recurrence_period_start_date = each.value.start_date
  recurrence_period_end_date   = each.value.end_date
  export_data_options {
    type       = each.value.cost_type
    time_frame = "MonthToDate"
  }
  export_data_storage_location {
    container_id     = each.value.container_id
    root_folder_path = each.value.root_folder_path
  }
}
resource "azurerm_cost_anomaly_alert" "subscription" {
  for_each        = var.cost_anomalies
  name            = each.value.name
  display_name    = each.value.name
  subscription_id = "/subscriptions/${var.subscription_id}"
  email_addresses = each.value.email_addresses
  email_subject   = "Azure subscription cost anomaly"
}
resource "azurerm_policy_definition" "sandbox_expiry" {
  for_each            = var.sandbox_scope == null ? {} : { sandbox = var.sandbox_scope }
  name                = each.value.policy_name
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "Sandbox resources require an expiration_date tag"
  management_group_id = each.value.management_group_id
  policy_rule = jsonencode({
    "if" = { field = "tags['expiration_date']", exists = "false" }
    then = { effect = each.value.effect }
  })
}
resource "azurerm_management_group_policy_assignment" "sandbox_expiry" {
  for_each             = var.sandbox_scope == null ? {} : { sandbox = var.sandbox_scope }
  name                 = each.value.policy_name
  management_group_id  = each.value.management_group_id
  policy_definition_id = azurerm_policy_definition.sandbox_expiry[each.key].id
  enforce              = true
}
