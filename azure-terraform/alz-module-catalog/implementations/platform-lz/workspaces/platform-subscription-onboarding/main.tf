# Places CSP-provisioned subscriptions into their target management group and
# applies baseline + app-specific RBAC at subscription scope. Subscriptions are
# NOT created here (see platform-subscriptions / subscription-vending — retired).

data "tfe_outputs" "governance" {
  count        = var.use_tfe_outputs ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.governance_workspace_name
}

data "tfe_outputs" "authorization" {
  count        = var.use_tfe_outputs ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.authorization_workspace_name
}

locals {
  enabled = try(var.onboarding.enabled, false)

  governance_outputs = merge(
    try(data.tfe_outputs.governance[0].nonsensitive_values, {}),
    try(data.tfe_outputs.governance[0].values, {})
  )

  authorization_outputs = merge(
    try(data.tfe_outputs.authorization[0].nonsensitive_values, {}),
    try(data.tfe_outputs.authorization[0].values, {})
  )

  governance_management_group_ids = try(local.governance_outputs.management_group_ids, {})
  authorization_group_object_ids  = try(local.authorization_outputs.group_object_ids, {})

  # Explicit catalog wins over / augments the governance-published catalog.
  management_group_ids = merge(local.governance_management_group_ids, var.management_group_ids)
  group_object_ids     = merge(local.authorization_group_object_ids, var.group_object_ids)
}

module "subscription_onboarding" {
  source = "../../../../patterns/terraform-azurerm-compeer-subscription-onboarding"
  count  = local.enabled ? 1 : 0

  providers = {
    azurerm = azurerm
  }

  management_group_ids      = local.management_group_ids
  group_object_ids          = local.group_object_ids
  root_management_group_id  = try(var.onboarding.root_management_group_id, null)
  default_tags              = try(var.onboarding.default_tags, {})
  baseline_role_assignments = try(var.onboarding.baseline_role_assignments, {})
  subscriptions             = try(var.onboarding.subscriptions, {})
  legacy_policy_removals    = try(var.onboarding.legacy_policy_removals, {})
}

# -----------------------------------------------------------------------------
# Legacy policy assignment removal — import blocks
#
# The pattern module declares azurerm_subscription_policy_assignment.legacy_removal
# / azurerm_resource_group_policy_assignment.legacy_removal, but Terraform only
# allows `import` blocks in the ROOT module — this workspace root is that root.
# See the pattern's variables.tf (legacy_policy_removals) and README for the
# full two-phase import-then-destroy workflow and rationale.
# -----------------------------------------------------------------------------

locals {
  legacy_policy_removals   = try(var.onboarding.legacy_policy_removals, {})
  onboarding_subscriptions = try(var.onboarding.subscriptions, {})

  legacy_sub_removals = { for k, r in local.legacy_policy_removals : k => r if r.scope_type == "subscription" }
  legacy_rg_removals  = { for k, r in local.legacy_policy_removals : k => r if r.scope_type == "resource_group" }
  legacy_removal_subscription_ids = {
    for k, r in local.legacy_policy_removals : k => local.onboarding_subscriptions[r.subscription_key].subscription_id
  }
}

import {
  for_each = local.legacy_sub_removals

  to = module.subscription_onboarding[0].azurerm_subscription_policy_assignment.legacy_removal[each.key]
  id = "/subscriptions/${local.legacy_removal_subscription_ids[each.key]}/providers/Microsoft.Authorization/policyAssignments/${each.value.assignment_name}"
}

import {
  for_each = local.legacy_rg_removals

  to = module.subscription_onboarding[0].azurerm_resource_group_policy_assignment.legacy_removal[each.key]
  id = "/subscriptions/${local.legacy_removal_subscription_ids[each.key]}/resourceGroups/${each.value.resource_group_name}/providers/Microsoft.Authorization/policyAssignments/${each.value.assignment_name}"
}
