module "alz" {
  source  = "Azure/avm-ptn-alz/azurerm"
  version = "0.21.0"

  architecture_name  = var.architecture_name
  location           = var.location
  parent_resource_id = "/providers/Microsoft.Management/managementGroups/${var.root_parent_management_group_id}"
  enable_telemetry   = var.enable_telemetry
}

# Use explicit role-assignment modules for approved enterprise groups at MG scope.
module "management_group_rbac" {
  for_each = var.management_group_role_assignments
  source   = "Azure/avm-res-authorization-roleassignment/azurerm"
  version  = "0.3.1"

  principal_id                     = each.value.principal_id
  role_definition_id_or_name       = each.value.role_definition_id_or_name
  scope                            = "/providers/Microsoft.Management/managementGroups/${var.root_parent_management_group_id}"
  skip_service_principal_aad_check = false
  enable_telemetry                 = var.enable_telemetry
}


# IAM-02: custom role definition is an AVM gap for this workbook. Use the
# Compeer HCP module and keep the role permission sets as stack inputs.
module "custom_role_definitions" {
  for_each = var.custom_role_definitions
  source   = "app.terraform.io/Compeer-Financial-Services/compeer-role-definition/azurerm"
  version  = "1.0.0"

  name        = each.value.name
  scope       = "/providers/Microsoft.Management/managementGroups/${var.root_parent_management_group_id}"
  description = each.value.description
  permissions = {
    default = {
      actions          = tolist(each.value.actions)
      not_actions      = tolist(each.value.not_actions)
      data_actions     = tolist(each.value.data_actions)
      not_data_actions = tolist(each.value.not_data_actions)
    }
  }
  assignable_scopes = tolist(each.value.assignable_scopes)
}

# GOV-05/GOV-06/GOV-07/GOV-11: AVM ALZ supplies the CAF library; Compeer
# policy-baseline carries enterprise-specific definitions, initiatives,
# assignments, DINE wiring, tagging schema, and controlled exemptions.
module "policy_baseline" {
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-policy-baseline/azurerm"
  version = "1.0.0"

  policy_definitions           = var.policy_definitions
  policy_set_definitions       = var.policy_set_definitions
  management_group_assignments = var.management_group_policy_assignments
  subscription_assignments     = var.subscription_policy_assignments
  resource_group_assignments   = var.resource_group_policy_assignments
  exemptions                   = var.policy_exemptions
}
