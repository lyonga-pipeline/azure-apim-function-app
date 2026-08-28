module "workspaces" {
  source   = "../../modules/hcp-workspace"
  for_each = var.workspaces

  organization      = var.organization_name
  project_id        = tfe_project.alz.id
  name              = each.value.name
  description       = each.value.description
  working_directory = each.value.working_directory
  vcs_identifier    = "${var.ado_organization_name}/${var.ado_project_name}/_git/${var.repositories[each.value.repository_key].name}"
  branch             = each.value.branch
  oauth_token_id     = data.tfe_oauth_client.ado.oauth_token_id

  execution_mode        = each.value.execution_mode
  agent_pool_id         = each.value.execution_mode == "agent" ? data.tfe_agent_pool.existing[each.value.agent_pool_name].id : null
  auto_apply            = each.value.auto_apply
  speculative_enabled   = each.value.speculative_enabled
  file_triggers_enabled = each.value.file_triggers_enabled
  trigger_patterns      = each.value.trigger_patterns
  terraform_version     = each.value.terraform_version
  assessments_enabled   = each.value.assessments_enabled

  tags = merge({
    "landing-zone" = "new-alz"
    "domain"       = each.key
    "managed-by"   = "terraform"
  }, each.value.tags)
}

resource "tfe_workspace_variable_set" "workspace_specific" {
  for_each = local.workspace_variable_set_links

  workspace_id    = module.workspaces[each.value.workspace_key].id
  variable_set_id = tfe_variable_set.alz[each.value.variable_set_key].id
}

resource "tfe_variable" "workspace_tf" {
  for_each = local.workspace_tf_variables

  workspace_id = module.workspaces[each.value.workspace_key].id
  key          = each.value.key
  value        = each.value.value
  category     = "terraform"
  description  = each.value.description
  sensitive    = each.value.sensitive
  hcl          = each.value.hcl
}

resource "tfe_variable" "workspace_env" {
  for_each = local.workspace_env_variables

  workspace_id = module.workspaces[each.value.workspace_key].id
  key          = each.value.key
  value        = each.value.value
  category     = "env"
  description  = each.value.description
  sensitive    = each.value.sensitive
}
