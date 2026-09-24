resource "terraform_data" "onboarding_contract" {
  input = {
    subscription_keys = sort(keys(var.subscriptions))
  }

  lifecycle {
    precondition {
      condition = local.contract_valid
      error_message = join(" ", compact([
        length(local.unresolved_target_keys) > 0 ? "subscriptions reference management group keys not present in management_group_ids: ${join(", ", local.unresolved_target_keys)}." : "",
        length(local.unresolved_principal_group_keys) > 0 ? "RBAC assignments reference principal_group_key values not present in group_object_ids: ${join(", ", local.unresolved_principal_group_keys)}." : "",
      ]))
    }
  }
}

# Move each already-existing subscription from the Tenant Root Group to its
# target management group. Azure enforces single-MG membership, so creating this
# association relocates the subscription; destroying it returns the subscription
# to the root group.
resource "azurerm_management_group_subscription_association" "platform_subscription_placement" {
  for_each = local.subscriptions

  management_group_id = local.subscription_target_mg_ids[each.key]
  subscription_id     = "/subscriptions/${each.value.subscription_id}"

  depends_on = [terraform_data.onboarding_contract]
}

module "baseline_role_assignments" {
  source = "../../modules/terraform-azurerm-compeer-role-assignments"

  assignments = local.baseline_assignment_inputs

  depends_on = [azurerm_management_group_subscription_association.platform_subscription_placement]
}

module "app_role_assignments" {
  source = "../../modules/terraform-azurerm-compeer-role-assignments"

  assignments = local.app_assignment_inputs

  depends_on = [azurerm_management_group_subscription_association.platform_subscription_placement]
}
