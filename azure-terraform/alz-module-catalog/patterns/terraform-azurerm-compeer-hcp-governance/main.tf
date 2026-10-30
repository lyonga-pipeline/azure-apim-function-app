# PHASE2 NEW: IAC-06 only. Team RBAC and repo/workspace creation are Phase 3 and excluded.
data "tfe_workspace" "existing" {
  for_each     = var.workspace_settings
  name         = each.value.workspace_name
  organization = var.organization
}
resource "tfe_workspace_settings" "assessments" {
  for_each            = var.workspace_settings
  workspace_id        = each.value.workspace_id
  execution_mode      = each.value.execution_mode
  agent_pool_id       = each.value.agent_pool_id
  assessments_enabled = each.value.assessments_enabled

  # Drift enablement must not silently change apply approval or existing state access.
  auto_apply                = data.tfe_workspace.existing[each.key].auto_apply
  global_remote_state       = data.tfe_workspace.existing[each.key].global_remote_state
  project_remote_state      = data.tfe_workspace.existing[each.key].project_remote_state
  remote_state_consumer_ids = data.tfe_workspace.existing[each.key].global_remote_state || data.tfe_workspace.existing[each.key].project_remote_state ? null : data.tfe_workspace.existing[each.key].remote_state_consumer_ids
  lifecycle {
    precondition {
      condition     = data.tfe_workspace.existing[each.key].id == each.value.workspace_id && data.tfe_workspace.existing[each.key].execution_mode == each.value.execution_mode
      error_message = "Resolve the actual workspace name/ID and current execution mode before adopting health-assessment settings."
    }
    precondition {
      condition     = each.value.remote_state_consumer_ids == null ? true : each.value.remote_state_consumer_ids == data.tfe_workspace.existing[each.key].remote_state_consumer_ids
      error_message = "Explicit consumers must match current HCP settings. Changing state-sharing permissions is not part of drift enablement."
    }
  }
}
