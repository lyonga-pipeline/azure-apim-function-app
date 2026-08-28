resource "tfe_policy_set" "opa" {
  count = var.opa_policy_set.enabled ? 1 : 0

  name                   = var.opa_policy_set.name
  description            = var.opa_policy_set.description
  organization           = var.organization_name
  kind                   = "opa"
  global                 = false
  overridable            = var.opa_policy_set.overridable
  agent_enabled          = var.opa_policy_set.agent_enabled
  policy_tool_version    = var.opa_policy_set.policy_tool_version
  policies_path          = var.opa_policy_set.policies_path
  policy_update_patterns = var.opa_policy_set.policy_update_patterns

  vcs_repo {
    identifier     = "${var.ado_organization_name}/${var.ado_project_name}/_git/${var.repositories[var.opa_policy_set.repository_key].name}"
    branch         = var.opa_policy_set.branch
    oauth_token_id = data.tfe_oauth_client.ado.oauth_token_id
  }
}

resource "tfe_project_policy_set" "opa" {
  count = var.opa_policy_set.enabled ? 1 : 0

  project_id    = tfe_project.alz.id
  policy_set_id = tfe_policy_set.opa[0].id
}
