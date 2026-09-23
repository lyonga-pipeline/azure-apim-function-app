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
