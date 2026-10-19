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
