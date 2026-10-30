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

module "policy" {
  source = "../../../../patterns/terraform-azurerm-compeer-platform-policy"
  count  = local.enabled ? 1 : 0

  providers = {
    azurerm = azurerm
  }

  subscription_id                     = var.execution_subscription_id
  management_group_ids                = local.management_group_ids
  policy_assignment_location          = try(var.policy.policy_assignment_location, var.location)
  custom_policy_definitions           = merge(try(var.policy.custom_policy_definitions, {}), local.diagnostic_audit_definitions, local.diagnostic_registered_all_logs_definitions, local.diagnostic_dine_definitions, local.flow_logging_definitions)
  custom_policy_set_definitions       = try(var.policy.custom_policy_set_definitions, {})
  management_group_policy_assignments = merge(try(var.policy.management_group_policy_assignments, {}), local.diagnostic_audit_assignments, local.diagnostic_builtin_audit_assignments, local.diagnostic_registered_all_logs_assignments)
  subscription_policy_assignments     = try(var.policy.subscription_policy_assignments, {})
  resource_group_policy_assignments   = try(var.policy.resource_group_policy_assignments, {})
  policy_exemptions                   = try(var.policy.policy_exemptions, {})
  private_only_connectivity           = try(var.policy.private_only_connectivity, {})
  remediation                         = local.remediation

  depends_on = [terraform_data.enterprise_policy_contract, terraform_data.existing_resource_remediation_contract]
}

# =============================================================================
# PHASE 2 CHANGES - additive, opt-in; preserve existing resource/state ownership.
# Adopt this marked section with phase2_*.tf, phase2-tests/ and phase2.tfvars.example.
# =============================================================================

locals {
  phase2_policy_requested          = length(var.phase2_audit_initiatives) + length(var.phase2_exemptions) + (var.phase2_sandbox_scope == null ? 0 : 1) > 0
  phase2_existing_assignment_names = [for key, value in try(var.policy.management_group_policy_assignments, {}) : lower(coalesce(try(value.name, null), key))]
}
resource "terraform_data" "phase2_policy_contract" {
  count = local.phase2_policy_requested ? 1 : 0
  lifecycle {
    precondition {
      condition     = local.enabled
      error_message = "Phase 2 policy extensions must run from the enabled existing policy owner."
    }
    precondition {
      condition     = alltrue([for item in values(var.phase2_audit_initiatives) : !contains(local.phase2_existing_assignment_names, lower(item.name))])
      error_message = "An existing policy input already owns this assignment name. Extend the existing assignment instead of duplicating it."
    }
    precondition {
      condition     = alltrue([for item in values(var.phase2_exemptions) : !contains([for key in keys(try(var.policy.policy_exemptions, {})) : lower(key)], lower(item.name))])
      error_message = "An existing exemption already owns this name. Renew that exemption in its original input."
    }
    precondition {
      condition = var.phase2_sandbox_scope == null ? true : !contains(concat(
        [for key in keys(try(var.policy.custom_policy_definitions, {})) : lower(key)],
        local.phase2_existing_assignment_names
      ), lower(var.phase2_sandbox_scope.policy_name))
      error_message = "Sandbox expiry policy already exists in the legacy policy input; do not create another owner."
    }
  }
}
module "phase2_policy" {
  source            = "../../../../patterns/terraform-azurerm-compeer-phase2-governance"
  count             = local.enabled && local.phase2_policy_requested ? 1 : 0
  subscription_id   = var.execution_subscription_id
  location          = var.location
  audit_initiatives = var.phase2_audit_initiatives
  exemptions        = var.phase2_exemptions
  sandbox_scope     = var.phase2_sandbox_scope
  # FinOps is deliberately not managed here. Existing budget owners remain unchanged.
  budgets        = {}
  cost_exports   = {}
  cost_anomalies = {}
  depends_on     = [terraform_data.phase2_policy_contract]
}
