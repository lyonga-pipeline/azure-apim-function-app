locals {
  enabled = try(var.governance.enabled, false)
}

module "governance" {
  source = "../../../../patterns/terraform-azurerm-compeer-global-governance"
  count  = local.enabled ? 1 : 0

  providers = {
    azurerm = azurerm
  }

  subscription_id                     = var.execution_subscription_id
  root_management_group_id            = try(var.governance.root_management_group_id, null)
  management_groups                   = local.std_management_groups
  subscription_placements             = try(var.governance.subscription_placements, {})
  policy_assignment_location          = try(var.governance.policy_assignment_location, var.location)
  custom_policy_definitions           = try(var.governance.custom_policy_definitions, {})
  custom_policy_set_definitions       = try(var.governance.custom_policy_set_definitions, {})
  management_group_policy_assignments = try(var.governance.management_group_policy_assignments, {})
  subscription_policy_assignments     = try(var.governance.subscription_policy_assignments, {})
  custom_role_definitions             = try(var.governance.custom_role_definitions, {})
  role_assignments                    = try(var.governance.role_assignments, {})
  management_group_budgets            = try(var.governance.management_group_budgets, {})
  policy_baseline                     = try(var.governance.policy_baseline, {})
}
