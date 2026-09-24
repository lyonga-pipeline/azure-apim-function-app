locals {
  enabled = try(var.onboarding.enabled, false)

  governance_outputs = merge(
    try(data.tfe_outputs.governance[0].nonsensitive_values, {}),
    try(data.tfe_outputs.governance[0].values, {})
  )

  authorization_outputs = merge(
    try(data.tfe_outputs.authorization[0].nonsensitive_values, {}),
    try(data.tfe_outputs.authorization[0].values, {})
  )

  governance_management_group_ids = try(local.governance_outputs.management_group_ids, {})
  authorization_group_object_ids  = try(local.authorization_outputs.group_object_ids, {})

  management_group_ids = merge(local.governance_management_group_ids, var.management_group_ids)
  group_object_ids     = merge(local.authorization_group_object_ids, var.group_object_ids)
}
