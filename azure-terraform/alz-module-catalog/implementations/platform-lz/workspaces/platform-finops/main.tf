# =============================================================================
# PHASE 2 CHANGES - additive, opt-in; preserve existing resource/state ownership.
# Standalone subscription FinOps root; do not deploy as a policy workspace.
# =============================================================================

resource "terraform_data" "finops_contract" {
  count = length(var.budgets) + length(var.cost_exports) + length(var.cost_anomalies) > 0 ? 1 : 0
  lifecycle {
    precondition {
      condition     = var.ownership_confirmed
      error_message = "Review existing subscription budget/export ownership before enabling this FinOps root."
    }
    precondition {
      condition     = length(setintersection(toset([for name in var.existing_budget_names : lower(name)]), toset([for budget in values(var.budgets) : lower(budget.name)]))) == 0
      error_message = "This budget is already retained by another owner; extend/import its original configuration instead."
    }
  }
}
module "finops" {
  source          = "../../../../patterns/terraform-azurerm-compeer-phase2-governance"
  subscription_id = var.subscription_id
  location        = var.location
  budgets         = var.budgets
  cost_exports    = var.cost_exports
  cost_anomalies  = var.cost_anomalies
  # No MG policy, exemptions or sandbox assignments in a FinOps state.
  audit_initiatives = {}
  exemptions        = {}
  sandbox_scope     = null
  depends_on        = [terraform_data.finops_contract]
}
output "ids" { value = module.finops }
