locals {
  management_group_ids = {
    for key, value in var.management_group_ids : key => (
      startswith(trimspace(value), "/providers/Microsoft.Management/managementGroups/")
      ? trimspace(value)
      : "/providers/Microsoft.Management/managementGroups/${trimspace(value)}"
    )
  }

  subscription_target_mg_ids = {
    for key, subscription in var.subscriptions : key => (
      subscription.target_management_group_id != null
      ? (
        startswith(trimspace(subscription.target_management_group_id), "/providers/Microsoft.Management/managementGroups/")
        ? trimspace(subscription.target_management_group_id)
        : "/providers/Microsoft.Management/managementGroups/${trimspace(subscription.target_management_group_id)}"
      )
      : lookup(local.management_group_ids, subscription.target_management_group_key, null)
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

  contract_valid = (
    length(local.unresolved_target_keys) == 0 &&
    length(local.unresolved_principal_group_keys) == 0
  )

  subscriptions                    = local.contract_valid ? var.subscriptions : {}
  unresolved_principal_placeholder = "00000000-0000-0000-0000-000000000000"

  baseline_assignment_inputs = {
    for pair in flatten([
      for subscription_key, subscription in local.subscriptions : [
        for assignment_key, assignment in var.baseline_role_assignments : {
          key = "${subscription_key}::baseline::${assignment_key}"
          value = {
            name                             = null
            scope                            = "/subscriptions/${subscription.subscription_id}"
            principal_id                     = try(assignment.principal_id, null) != null ? assignment.principal_id : lookup(var.group_object_ids, assignment.principal_group_key, local.unresolved_principal_placeholder)
            role_definition_name             = assignment.role_definition_name
            role_definition_id               = assignment.role_definition_id
            principal_type                   = try(assignment.principal_group_key, null) != null ? "Group" : assignment.principal_type
            description                      = coalesce(assignment.description, "Platform baseline RBAC for onboarded subscription ${subscription_key}")
            condition                        = assignment.condition
            condition_version                = assignment.condition_version
            skip_service_principal_aad_check = assignment.skip_service_principal_aad_check
          }
        }
        if subscription.apply_baseline_rbac
      ]
    ]) : pair.key => pair.value
  }

  app_assignment_inputs = {
    for pair in flatten([
      for subscription_key, subscription in local.subscriptions : [
        for assignment_key, assignment in subscription.app_role_assignments : {
          key = "${subscription_key}::app::${assignment_key}"
          value = {
            name                             = assignment.name
            scope                            = "/subscriptions/${subscription.subscription_id}"
            principal_id                     = try(assignment.principal_id, null) != null ? assignment.principal_id : lookup(var.group_object_ids, assignment.principal_group_key, local.unresolved_principal_placeholder)
            role_definition_name             = assignment.role_definition_name
            role_definition_id               = assignment.role_definition_id
            principal_type                   = try(assignment.principal_group_key, null) != null ? "Group" : assignment.principal_type
            description                      = assignment.description
            condition                        = assignment.condition
            condition_version                = assignment.condition_version
            skip_service_principal_aad_check = assignment.skip_service_principal_aad_check
          }
        }
      ]
    ]) : pair.key => pair.value
  }
}
