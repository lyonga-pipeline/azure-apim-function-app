# Initiative naming is opt-in through `domain`; explicit names remain supported.
module "naming_initiative" {
  source      = "../../modules/terraform-azurerm-compeer-naming"
  for_each    = merge(var.custom_policy_set_definitions, local.poc_set_definitions)
  region      = "centralus"
  environment = "shared"
  domain      = try(each.value.domain, null)
  purpose     = each.key
}

module "naming_assignment" {
  source       = "../../modules/terraform-azurerm-compeer-naming"
  for_each     = merge(var.management_group_policy_assignments, local.poc_assignments, var.subscription_policy_assignments)
  region       = "centralus"
  environment  = "shared"
  policy       = try(each.value.policy, null)
  policy_scope = try(each.value.policy_scope, null)
}

module "policy" {
  source = "../../modules/terraform-azurerm-compeer-policy"

  policy_definitions           = local.policy_definitions_input
  policy_set_definitions       = local.policy_set_definitions_input
  management_group_assignments = local.management_group_policy_assignments_input
  subscription_assignments     = local.subscription_policy_assignments_input
  resource_group_assignments   = local.resource_group_policy_assignments_input
  exemptions                   = local.policy_exemptions_input

  depends_on = [terraform_data.remediation_contract]
}
