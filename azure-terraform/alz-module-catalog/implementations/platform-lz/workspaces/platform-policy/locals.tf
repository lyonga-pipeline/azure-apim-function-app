locals {
  enabled = try(var.policy.enabled, false)

  governance_outputs = merge(
    try(data.tfe_outputs.governance[0].nonsensitive_values, {}),
    try(data.tfe_outputs.governance[0].values, {})
  )

  management_outputs = merge(
    try(data.tfe_outputs.management[0].nonsensitive_values, {}),
    try(data.tfe_outputs.management[0].values, {})
  )

  management_group_ids = merge(
    try(local.governance_outputs.management_group_ids, {}),
    var.management_group_ids
  )

  log_analytics_workspace_id = coalesce(
    try(var.policy.remediation.log_analytics_workspace_id, null),
    try(local.management_outputs.log_analytics_workspace_id, null),
    try(local.management_outputs.primary_log_analytics_workspace_id, null),
    "unset",
  )

  remediation = merge(
    try(var.policy.remediation, {}),
    local.log_analytics_workspace_id == "unset" ? {} : { log_analytics_workspace_id = local.log_analytics_workspace_id },
  )
}
