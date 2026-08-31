# =============================================================================
# ⛔ NOT DEPLOYED. Compeer subscriptions are created by the CSP partner, not by
# Terraform. This workspace drives the `subscription-vending` pattern (which
# CREATES subscriptions) and is kept only for a future EA/MCA billing model.
#
# `var.subscription_vending` defaults to enabled = false / vending_enabled =
# false and MUST stay that way. Do not create an HCP Terraform workspace from
# this directory.
#
# Live work: `platform-subscription-onboarding` (places CSP-created
# subscriptions into their management group and applies baseline + app RBAC).
# =============================================================================

data "tfe_outputs" "governance" {
  count        = var.use_tfe_outputs ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.governance_workspace_name
}

locals {
  enabled = try(var.subscription_vending.enabled, false)

  governance_outputs = merge(
    try(data.tfe_outputs.governance[0].nonsensitive_values, {}),
    try(data.tfe_outputs.governance[0].values, {})
  )

  governance_management_groups = {
    for key, id in try(local.governance_outputs.management_group_ids, {}) : key => {
      management_group_id = id
    }
  }

  management_groups = length(try(var.subscription_vending.management_groups, {})) > 0 ? {
    for key, group in try(var.subscription_vending.management_groups, {}) : key => merge(
      group,
      try(local.governance_management_groups[key], {})
    )
  } : local.governance_management_groups
}

module "subscription_vending" {
  source = "../../../../patterns/terraform-azurerm-compeer-subscription-vending"
  count  = local.enabled ? 1 : 0

  providers = {
    azurerm = azurerm
  }

  subscription_id               = var.execution_subscription_id
  tenant_id                     = var.tenant_id
  vending_enabled               = try(var.subscription_vending.vending_enabled, false)
  default_billing_scope_id      = try(var.subscription_vending.default_billing_scope_id, try(var.subscription_vending.billing_scope, null))
  billing_account_name          = try(var.subscription_vending.billing_account_name, null)
  billing_profile_name          = try(var.subscription_vending.billing_profile_name, null)
  invoice_section_name          = try(var.subscription_vending.invoice_section_name, null)
  default_tags                  = try(var.subscription_vending.default_tags, {})
  management_groups             = local.management_groups
  subscriptions                 = try(var.subscription_vending.subscriptions, {})
  subscription_role_assignments = try(var.subscription_vending.subscription_role_assignments, {})
  subscription_timeouts         = try(var.subscription_vending.subscription_timeouts, {})
}
