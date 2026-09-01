# =============================================================================
# DeployIfNotExists / Modify remediation bundle
#
# Auto-remediation is what makes the landing zone self-healing: diagnostic
# settings to Log Analytics, Defender plan enablement, AMA/DCR association,
# private-DNS-zone-group attachment, etc. (deploy-runbook.tf §2.4 / §3 gate:
# "required diagnostics policy assigned").
#
# These assignments need a managed identity + a location, so they run in the
# policy workspace AFTER platform-management has created the Log Analytics
# workspace. The built-in policy/initiative IDs are tenant-verifiable, so the
# assignment set is caller-supplied - see the pattern README for the
# recommended list and the `az policy` command to confirm each ID.
# =============================================================================

locals {
  rem          = var.remediation
  rem_enabled  = try(local.rem.enabled, false)
  rem_mg_key   = try(local.rem.management_group_key, null)
  rem_location = try(local.rem.location, var.policy_assignment_location)
  rem_law_id   = try(local.rem.log_analytics_workspace_id, null)
  rem_identity = { type = "SystemAssigned" }

  # Each entry: { policy_definition_id (built-in, full ID), parameters = {},
  #               inject_law = optional(bool) - adds logAnalytics/workspaceId param }
  rem_assignments = { for k, v in try(local.rem.dine_assignments, {}) : k => v if local.rem_enabled }
}

resource "azurerm_management_group_policy_assignment" "remediation" {
  for_each = local.rem_assignments

  name                 = substr("rem-${each.key}", 0, 24)
  management_group_id  = local.management_group_scope_ids[local.rem_mg_key]
  policy_definition_id = each.value.policy_definition_id
  display_name         = try(each.value.display_name, "Remediation - ${each.key}")
  description          = try(each.value.description, "DeployIfNotExists remediation managed by platform-policy.")
  enforce              = try(each.value.enforce, true)
  location             = local.rem_location
  not_scopes           = try(each.value.not_scopes, null)

  parameters = jsonencode(merge(
    try(each.value.parameters, {}),
    try(each.value.inject_law, false) && local.rem_law_id != null ? {
      logAnalytics = { value = local.rem_law_id }
    } : {},
  ))

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    precondition {
      condition     = local.rem_mg_key != null
      error_message = "remediation.enabled requires remediation.management_group_key."
    }
    precondition {
      condition     = !try(each.value.inject_law, false) || local.rem_law_id != null
      error_message = "A remediation assignment sets inject_law but remediation.log_analytics_workspace_id is not provided."
    }
  }
}
