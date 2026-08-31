locals {
  # Normalize the resolved MG catalog to full resource IDs.
  management_group_ids = {
    for key, value in var.management_group_ids : key => (
      startswith(trimspace(value), "/providers/Microsoft.Management/managementGroups/")
      ? trimspace(value)
      : "/providers/Microsoft.Management/managementGroups/${trimspace(value)}"
    )
  }

  # Per-subscription target MG resource ID.
  subscription_target_mg_ids = {
    for key, s in var.subscriptions : key => (
      s.target_management_group_id != null
      ? (
        startswith(trimspace(s.target_management_group_id), "/providers/Microsoft.Management/managementGroups/")
        ? trimspace(s.target_management_group_id)
        : "/providers/Microsoft.Management/managementGroups/${trimspace(s.target_management_group_id)}"
      )
      : lookup(local.management_group_ids, s.target_management_group_key, null)
    )
  }

  unresolved_target_keys = sort([
    for key, id in local.subscription_target_mg_ids : key if id == null
  ])

  contract_valid = length(local.unresolved_target_keys) == 0

  subscriptions = local.contract_valid ? var.subscriptions : {}

  # Baseline RBAC: cartesian of (subscription that opts in) x (baseline entry).
  baseline_assignment_inputs = {
    for pair in flatten([
      for sub_key, s in local.subscriptions : [
        for ra_key, ra in var.baseline_role_assignments : {
          key = "${sub_key}::baseline::${ra_key}"
          value = {
            name                             = null
            scope                            = "/subscriptions/${s.subscription_id}"
            principal_id                     = ra.principal_id
            role_definition_name             = ra.role_definition_name
            role_definition_id               = ra.role_definition_id
            principal_type                   = ra.principal_type
            description                      = coalesce(ra.description, "Platform baseline RBAC for onboarded subscription ${sub_key}")
            condition                        = ra.condition
            condition_version                = ra.condition_version
            skip_service_principal_aad_check = ra.skip_service_principal_aad_check
          }
        }
        if s.apply_baseline_rbac
      ]
    ]) : pair.key => pair.value
  }

  # App-specific RBAC declared inline per subscription.
  app_assignment_inputs = {
    for pair in flatten([
      for sub_key, s in local.subscriptions : [
        for ra_key, ra in s.app_role_assignments : {
          key = "${sub_key}::app::${ra_key}"
          value = {
            name                             = ra.name
            scope                            = "/subscriptions/${s.subscription_id}"
            principal_id                     = ra.principal_id
            role_definition_name             = ra.role_definition_name
            role_definition_id               = ra.role_definition_id
            principal_type                   = ra.principal_type
            description                      = ra.description
            condition                        = ra.condition
            condition_version                = ra.condition_version
            skip_service_principal_aad_check = ra.skip_service_principal_aad_check
          }
        }
      ]
    ]) : pair.key => pair.value
  }
}

resource "terraform_data" "onboarding_contract" {
  input = {
    subscription_keys = sort(keys(var.subscriptions))
    default_tags      = var.default_tags
  }

  lifecycle {
    precondition {
      condition     = local.contract_valid
      error_message = "subscriptions reference management group keys not present in management_group_ids: ${join(", ", local.unresolved_target_keys)}."
    }
  }
}

# Move each already-existing subscription from the Tenant Root Group to its
# target management group. Azure enforces single-MG membership, so creating this
# association relocates the subscription; destroying it returns the subscription
# to the root group.
resource "azurerm_management_group_subscription_association" "placement" {
  for_each = local.subscriptions

  management_group_id = local.subscription_target_mg_ids[each.key]
  subscription_id     = "/subscriptions/${each.value.subscription_id}"

  depends_on = [terraform_data.onboarding_contract]
}

module "baseline_role_assignments" {
  source = "../../modules/terraform-azurerm-compeer-role-assignments"

  assignments = local.baseline_assignment_inputs

  depends_on = [azurerm_management_group_subscription_association.placement]
}

module "app_role_assignments" {
  source = "../../modules/terraform-azurerm-compeer-role-assignments"

  assignments = local.app_assignment_inputs

  depends_on = [azurerm_management_group_subscription_association.placement]
}
