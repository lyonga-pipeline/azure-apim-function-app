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

module "subscription_onboarding" {
  source = "../../../../patterns/terraform-azurerm-compeer-subscription-onboarding"
  count  = local.enabled ? 1 : 0

  providers = {
    azurerm = azurerm
  }

  management_group_ids      = local.management_group_ids
  group_object_ids          = local.group_object_ids
  baseline_role_assignments = try(var.onboarding.baseline_role_assignments, {})
  subscriptions             = try(var.onboarding.subscriptions, {})
}
