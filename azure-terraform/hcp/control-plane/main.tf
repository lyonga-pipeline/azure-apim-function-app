locals {
  policy_catalog = yamldecode(file(var.policy_scope_catalog_path))
  source_control = local.policy_catalog.source_control
  policy_sets    = local.policy_catalog.policy_sets
  policy_set     = local.policy_sets[var.policy_set_key]

  catalog_project_scopes      = try(local.policy_set.project_scopes, [])
  catalog_workspace_scopes    = try(local.policy_set.workspace_scopes, [])
  catalog_excluded_workspaces = try(local.policy_set.excluded_workspaces, [])

  project_scopes = toset(
    length(var.project_scopes) > 0 ? var.project_scopes : local.catalog_project_scopes
  )
  workspace_scopes = toset(
    length(var.workspace_scopes) > 0 ? var.workspace_scopes : local.catalog_workspace_scopes
  )
  excluded_workspaces = toset(
    length(var.excluded_workspaces) > 0 ? var.excluded_workspaces : local.catalog_excluded_workspaces
  )

  opa_policy_directory = abspath("${path.module}/${var.policy_source_root_path}/${local.policy_set.vcs_policy_directory}")
  enforcement_level    = try(local.policy_set.enforcement_level, "advisory")
}

data "tfe_slug" "opa_policy_directory" {
  source_path = local.opa_policy_directory
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
  slug                = data.tfe_slug.opa_policy_directory
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
