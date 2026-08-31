# Places CSP-provisioned subscriptions into their target management group and
# applies baseline + app-specific RBAC at subscription scope. Subscriptions are
# NOT created here (see platform-subscriptions / subscription-vending — retired).

data "tfe_outputs" "governance" {
  count        = var.use_tfe_outputs ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.governance_workspace_name
}

locals {
  enabled = try(var.onboarding.enabled, false)

  governance_outputs = merge(
    try(data.tfe_outputs.governance[0].nonsensitive_values, {}),
    try(data.tfe_outputs.governance[0].values, {})
  )

  governance_management_group_ids = try(local.governance_outputs.management_group_ids, {})

  # Explicit catalog wins over / augments the governance-published catalog.
  management_group_ids = merge(local.governance_management_group_ids, var.management_group_ids)
}

module "subscription_onboarding" {
  source = "../../../../patterns/terraform-azurerm-compeer-subscription-onboarding"
  count  = local.enabled ? 1 : 0

  providers = {
    azurerm = azurerm
  }

  management_group_ids      = local.management_group_ids
  root_management_group_id  = try(var.onboarding.root_management_group_id, null)
  default_tags              = try(var.onboarding.default_tags, {})
  baseline_role_assignments = try(var.onboarding.baseline_role_assignments, {})
  subscriptions             = try(var.onboarding.subscriptions, {})
}
