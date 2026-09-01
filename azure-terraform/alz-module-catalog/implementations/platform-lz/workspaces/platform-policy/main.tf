data "tfe_outputs" "governance" {
  count        = var.use_tfe_outputs && var.tfe_organization != null ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.governance_workspace_name
}

data "tfe_outputs" "management" {
  count        = var.use_tfe_outputs && var.tfe_organization != null ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.management_workspace_name
}

locals {
  enabled = try(var.policy.enabled, false)

  governance_outputs = merge(
    try(data.tfe_outputs.governance[0].nonsensitive_values, {}),
    try(data.tfe_outputs.governance[0].values, {})
  )

  management_outputs = merge(
    try(data.tfe_outputs.management[0].nonsensitive_values, {}),
    try(data.tfe_outputs.management[0].values, {})
  )

  management_group_ids = merge(
    try(local.governance_outputs.management_group_ids, {}),
    var.management_group_ids
  )

  # Log Analytics workspace ID for DINE remediation - explicit input wins,
  # else the platform-management output.
  log_analytics_workspace_id = coalesce(
    try(var.policy.remediation.log_analytics_workspace_id, null),
    try(local.management_outputs.log_analytics_workspace_id, null),
    try(local.management_outputs.primary_log_analytics_workspace_id, null),
    "unset",
  )

  remediation = merge(
    try(var.policy.remediation, {}),
    local.log_analytics_workspace_id == "unset" ? {} : { log_analytics_workspace_id = local.log_analytics_workspace_id },
  )
}

module "policy" {
  source = "../../../../patterns/terraform-azurerm-compeer-platform-policy"
  count  = local.enabled ? 1 : 0

  providers = {
    azurerm = azurerm
  }

  subscription_id                     = var.execution_subscription_id
  management_group_ids                = local.management_group_ids
  policy_assignment_location          = try(var.policy.policy_assignment_location, var.location)
  custom_policy_definitions           = try(var.policy.custom_policy_definitions, {})
  custom_policy_set_definitions       = try(var.policy.custom_policy_set_definitions, {})
  management_group_policy_assignments = try(var.policy.management_group_policy_assignments, {})
  subscription_policy_assignments     = try(var.policy.subscription_policy_assignments, {})
  resource_group_policy_assignments   = try(var.policy.resource_group_policy_assignments, {})
  policy_exemptions                   = try(var.policy.policy_exemptions, {})
  private_only_connectivity           = try(var.policy.private_only_connectivity, {})
  remediation                         = local.remediation
}
