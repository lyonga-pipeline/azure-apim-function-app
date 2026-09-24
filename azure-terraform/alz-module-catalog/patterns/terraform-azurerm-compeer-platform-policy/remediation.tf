# Validate the contract before creating DINE/Modify assignments.
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
