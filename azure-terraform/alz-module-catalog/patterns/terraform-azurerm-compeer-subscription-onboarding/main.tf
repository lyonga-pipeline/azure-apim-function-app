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

  baseline_principal_group_keys = [
    for assignment in values(var.baseline_role_assignments) : assignment.principal_group_key
    if try(assignment.principal_group_key, null) != null
  ]

  app_principal_group_keys = flatten([
    for subscription in values(var.subscriptions) : [
      for assignment in values(subscription.app_role_assignments) : assignment.principal_group_key
      if try(assignment.principal_group_key, null) != null
    ]
  ])

  unresolved_principal_group_keys = sort(tolist(setsubtract(
    toset(concat(local.baseline_principal_group_keys, local.app_principal_group_keys)),
    toset(keys(var.group_object_ids))
  )))

  contract_valid = length(local.unresolved_target_keys) == 0 && length(local.unresolved_principal_group_keys) == 0

  subscriptions = local.contract_valid ? var.subscriptions : {}

  unresolved_principal_placeholder = "00000000-0000-0000-0000-000000000000"

  # Baseline RBAC: cartesian of (subscription that opts in) x (baseline entry).
  baseline_assignment_inputs = {
    for pair in flatten([
      for sub_key, s in local.subscriptions : [
        for ra_key, ra in var.baseline_role_assignments : {
          key = "${sub_key}::baseline::${ra_key}"
          value = {
            name                             = null
            scope                            = "/subscriptions/${s.subscription_id}"
            principal_id                     = try(ra.principal_id, null) != null ? ra.principal_id : lookup(var.group_object_ids, ra.principal_group_key, local.unresolved_principal_placeholder)
            role_definition_name             = ra.role_definition_name
            role_definition_id               = ra.role_definition_id
            principal_type                   = try(ra.principal_group_key, null) != null ? "Group" : ra.principal_type
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
            principal_id                     = try(ra.principal_id, null) != null ? ra.principal_id : lookup(var.group_object_ids, ra.principal_group_key, local.unresolved_principal_placeholder)
            role_definition_name             = ra.role_definition_name
            role_definition_id               = ra.role_definition_id
            principal_type                   = try(ra.principal_group_key, null) != null ? "Group" : ra.principal_type
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
