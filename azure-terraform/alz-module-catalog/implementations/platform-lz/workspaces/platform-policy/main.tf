data "tfe_outputs" "governance" {
  count        = var.use_tfe_outputs && var.tfe_organization != null ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.governance_workspace_name
}

locals {
  enabled = try(var.policy.enabled, false)

  governance_outputs = merge(
    try(data.tfe_outputs.governance[0].nonsensitive_values, {}),
    try(data.tfe_outputs.governance[0].values, {})
  )

  management_group_ids = merge(
    try(local.governance_outputs.management_group_ids, {}),
    var.management_group_ids
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
}
