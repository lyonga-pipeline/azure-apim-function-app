resource "tfe_workspace" "this" {
  name                          = var.name
  description                   = var.description
  organization                  = var.organization
  project_id                    = var.project_id
  working_directory             = var.working_directory
  speculative_enabled           = var.speculative_enabled
  file_triggers_enabled         = var.file_triggers_enabled
  trigger_patterns              = var.file_triggers_enabled ? var.trigger_patterns : null
  terraform_version             = var.terraform_version
  assessments_enabled           = var.assessments_enabled
  allow_destroy_plan            = false
  structured_run_output_enabled = true
  tags                          = var.tags

  vcs_repo {
    identifier     = var.vcs_identifier
    branch         = var.branch
    oauth_token_id = var.oauth_token_id
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "tfe_workspace_settings" "this" {
  workspace_id   = tfe_workspace.this.id
  execution_mode = var.execution_mode
  agent_pool_id  = var.execution_mode == "agent" ? var.agent_pool_id : null
  auto_apply     = var.auto_apply

  global_remote_state  = false
  project_remote_state = false
}
