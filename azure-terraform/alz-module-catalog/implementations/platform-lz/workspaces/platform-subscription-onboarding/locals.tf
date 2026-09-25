locals {
  enabled = try(var.onboarding.enabled, false)

  authorization_outputs_required = length(compact(concat(
    [
      for assignment in values(try(var.onboarding.baseline_role_assignments, {})) :
      try(assignment.principal_group_key, null)
    ],
    flatten([
      for subscription in values(try(var.onboarding.subscriptions, {})) : [
        for assignment in values(try(subscription.app_role_assignments, {})) :
        try(assignment.principal_group_key, null)
      ]
    ])
  ))) > 0

  governance_outputs = merge(
    try(data.tfe_outputs.governance[0].nonsensitive_values, {}),
    try(data.tfe_outputs.governance[0].values, {})
  )

  authorization_outputs = merge(
    try(data.tfe_outputs.authorization[0].nonsensitive_values, {}),
    try(data.tfe_outputs.authorization[0].values, {})
  )

  governance_management_group_ids = nonsensitive(try(local.governance_outputs.management_group_ids, {}))
  authorization_group_object_ids  = nonsensitive(try(local.authorization_outputs.group_object_ids, {}))

  management_group_ids = merge(local.governance_management_group_ids, nonsensitive(var.management_group_ids))
  group_object_ids     = merge(local.authorization_group_object_ids, nonsensitive(var.group_object_ids))
}
