locals {
  policy_catalog = yamldecode(file(var.policy_scope_catalog_path))
  source_control = local.policy_catalog.source_control
  policy_sets    = local.policy_catalog.policy_sets
  policy_set     = local.policy_sets[var.policy_set_key]

  project_scopes      = toset(try(local.policy_set.project_scopes, []))
  workspace_scopes    = toset(try(local.policy_set.workspace_scopes, []))
  excluded_workspaces = toset(try(local.policy_set.excluded_workspaces, []))

  policy_repo_branch   = try(local.source_control.branch, var.policy_repo_branch)
  opa_policy_directory = local.policy_set.vcs_policy_directory
  enforcement_level    = try(local.policy_set.enforcement_level, "advisory")
}

data "tfe_project" "policy_scope" {
  for_each = local.project_scopes

  organization = var.hcp_organization
  name         = each.value
}

data "tfe_workspace" "policy_scope" {
  for_each = local.workspace_scopes

  organization = var.hcp_organization
  name         = each.value
}

data "tfe_workspace" "policy_exclusion" {
  for_each = local.excluded_workspaces

  organization = var.hcp_organization
  name         = each.value
}

resource "tfe_policy_set" "opa" {
  name                = var.policy_set_name
  description         = local.policy_set.description
  organization        = var.hcp_organization
  kind                = "opa"
  agent_enabled       = true
  policy_tool_version = var.opa_policy_tool_version
  overridable         = local.enforcement_level == "mandatory" ? var.mandatory_policy_overridable : false
  policies_path       = local.opa_policy_directory
  policy_update_patterns = [
    "${local.opa_policy_directory}/**",
  ]

  vcs_repo {
    identifier         = var.policy_repo_identifier
    branch             = local.policy_repo_branch
    ingress_submodules = false
    oauth_token_id     = var.hcp_oauth_token_id
  }
}

resource "tfe_project_policy_set" "opa" {
  for_each = data.tfe_project.policy_scope

  policy_set_id = tfe_policy_set.opa.id
  project_id    = each.value.id
}

resource "tfe_workspace_policy_set" "opa" {
  for_each = data.tfe_workspace.policy_scope

  policy_set_id = tfe_policy_set.opa.id
  workspace_id  = each.value.id
}

resource "tfe_workspace_policy_set_exclusion" "opa" {
  for_each = data.tfe_workspace.policy_exclusion

  policy_set_id = tfe_policy_set.opa.id
  workspace_id  = each.value.id
}
