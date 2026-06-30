locals {
  policy_catalog = yamldecode(file(var.policy_scope_catalog_path))
  source_control = local.policy_catalog.source_control
  policy_sets    = local.policy_catalog.policy_sets
  policy_set     = local.policy_sets[var.policy_set_key]

  project_scopes      = toset(var.project_scopes)
  workspace_scopes    = toset(var.workspace_scopes)
  excluded_workspaces = toset(var.excluded_workspaces)

  opa_policy_directory = abspath("${path.module}/${var.policy_source_root_path}/${local.policy_set.vcs_policy_directory}")
  opa_policy_file      = startswith(var.opa_policy_file_path, "/") ? var.opa_policy_file_path : abspath("${path.module}/${var.policy_source_root_path}/${var.opa_policy_file_path}")
  enforcement_level    = try(local.policy_set.enforcement_level, "advisory")
  policy_set_id        = var.policy_content_mode == "none" ? data.tfe_policy_set.opa[0].id : tfe_policy_set.opa[0].id
}

data "tfe_slug" "opa_policy_directory" {
  count = var.policy_content_mode == "slug" ? 1 : 0

  source_path = local.opa_policy_directory
}

data "tfe_policy_set" "opa" {
  count = var.policy_content_mode == "none" ? 1 : 0

  organization = var.hcp_organization
  name         = var.policy_set_name
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

resource "tfe_policy" "opa" {
  count = var.policy_content_mode == "individual" ? 1 : 0

  name         = var.opa_policy_name
  description  = var.opa_policy_description
  organization = var.hcp_organization
  kind         = "opa"
  query        = var.opa_policy_query
  policy       = file(local.opa_policy_file)
  enforce_mode = local.enforcement_level
}

resource "tfe_policy_set" "opa" {
  count = var.policy_content_mode == "none" ? 0 : 1

  name                = var.policy_set_name
  description         = local.policy_set.description
  organization        = var.hcp_organization
  kind                = "opa"
  agent_enabled       = true
  policy_tool_version = var.opa_policy_tool_version
  overridable         = local.enforcement_level == "mandatory" ? var.mandatory_policy_overridable : false
  policy_ids          = var.policy_content_mode == "individual" ? [tfe_policy.opa[0].id] : null
  slug                = var.policy_content_mode == "slug" ? data.tfe_slug.opa_policy_directory[0] : null
}

resource "tfe_project_policy_set" "opa" {
  for_each = data.tfe_project.policy_scope

  policy_set_id = local.policy_set_id
  project_id    = each.value.id
}

resource "tfe_workspace_policy_set" "opa" {
  for_each = data.tfe_workspace.policy_scope

  policy_set_id = local.policy_set_id
  workspace_id  = each.value.id
}

resource "tfe_workspace_policy_set_exclusion" "opa" {
  for_each = data.tfe_workspace.policy_exclusion

  policy_set_id = local.policy_set_id
  workspace_id  = each.value.id
}
