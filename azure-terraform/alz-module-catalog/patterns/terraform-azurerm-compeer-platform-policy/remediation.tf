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
#
# The resulting entries fold into local.management_group_policy_assignments_input
# (main.tf) - remediation is just a management-group policy assignment with a
# SystemAssigned identity and LAW-parameter-injection business logic, and the
# actual azurerm_management_group_policy_assignment resource mechanics live
# in module.policy like every other assignment.
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

  # Keyed "rem-<key>" so it can merge safely with hand-authored /
  # private-only-connectivity assignments in the same map without colliding.
  remediation_assignments_input = {
    for k, v in local.rem_assignments : "rem-${k}" => {
      name                 = substr("rem-${k}", 0, 24)
      management_group_id  = try(local.management_group_scope_ids[local.rem_mg_key], null)
      policy_definition_id = v.policy_definition_id
      display_name         = try(v.display_name, "Remediation - ${k}")
      description          = try(v.description, "DeployIfNotExists remediation managed by platform-policy.")
      enforce              = try(v.enforce, true)
      location             = local.rem_location
      not_scopes           = try(v.not_scopes, null)
      identity             = local.rem_identity
      parameters = merge(
        try(v.parameters, {}),
        try(v.inject_law, false) && local.rem_law_id != null ? {
          logAnalytics = { value = local.rem_law_id }
        } : {},
      )
    }
  }
}

resource "terraform_data" "remediation_contract" {
  count = length(local.rem_assignments) > 0 ? 1 : 0

  input = sort(keys(local.rem_assignments))

  lifecycle {
    precondition {
      condition     = local.rem_mg_key != null
      error_message = "remediation.enabled requires remediation.management_group_key."
    }
    precondition {
      condition = alltrue([
        for k, v in local.rem_assignments : !try(v.inject_law, false) || local.rem_law_id != null
      ])
      error_message = "A remediation assignment sets inject_law but remediation.log_analytics_workspace_id is not provided."
    }
  }
}
