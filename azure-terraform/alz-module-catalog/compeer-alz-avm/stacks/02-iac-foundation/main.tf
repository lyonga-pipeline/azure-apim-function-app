locals {
  variable_set_variables = merge({}, [
    for set_key, set in var.variable_sets : {
      for variable_key, variable in try(set.variables, {}) : "${set_key}-${variable_key}" => merge(variable, {
        variable_set_key = set_key
      })
    }
  ]...)

  workspace_variables = merge({}, [
    for workspace_key, workspace in var.workspaces : {
      for variable_key, variable in try(workspace.variables, {}) : "${workspace_key}-${variable_key}" => merge(variable, {
        workspace_key = workspace_key
      })
    }
  ]...)

  variable_set_workspace_attachments = merge({}, [
    for set_key, set in var.variable_sets : {
      for workspace_key in try(set.workspace_keys, []) : "${set_key}-${workspace_key}" => {
        variable_set_key = set_key
        workspace_key    = workspace_key
      }
    }
  ]...)

  variable_set_project_attachments = merge({}, [
    for set_key, set in var.variable_sets : {
      for project_key in try(set.project_keys, []) : "${set_key}-${project_key}" => {
        variable_set_key = set_key
        project_key      = project_key
      }
    }
  ]...)
}

resource "tfe_project" "this" {
  for_each = var.projects

  name                           = each.value.name
  description                    = try(each.value.description, null)
  auto_destroy_activity_duration = try(each.value.auto_destroy_activity_duration, null)
  tags                           = try(each.value.tags, {})
}

resource "tfe_workspace" "this" {
  for_each = var.workspaces

  name                      = each.value.name
  project_id                = try(tfe_project.this[each.value.project_key].id, null)
  description               = try(each.value.description, null)
  working_directory         = try(each.value.working_directory, null)
  terraform_version         = try(each.value.terraform_version, null)
  auto_apply                = try(each.value.auto_apply, false)
  auto_apply_run_trigger    = try(each.value.auto_apply_run_trigger, false)
  allow_destroy_plan        = try(each.value.allow_destroy_plan, false)
  assessments_enabled       = try(each.value.assessments_enabled, true)
  queue_all_runs            = try(each.value.queue_all_runs, true)
  speculative_enabled       = try(each.value.speculative_enabled, true)
  file_triggers_enabled     = try(each.value.file_triggers_enabled, true)
  trigger_prefixes          = try(each.value.trigger_prefixes, null)
  trigger_patterns          = try(each.value.trigger_patterns, null)
  tag_names                 = try(each.value.tag_names, [])
  tags                      = try(each.value.tags, {})
  remote_state_consumer_ids = length(try(each.value.remote_state_consumer_workspace_keys, [])) == 0 ? null : [for key in each.value.remote_state_consumer_workspace_keys : tfe_workspace.this[key].id]
  global_remote_state       = try(each.value.global_remote_state, false)

  dynamic "vcs_repo" {
    for_each = try(each.value.vcs_repo, null) == null ? [] : [each.value.vcs_repo]
    content {
      identifier                 = vcs_repo.value.identifier
      branch                     = try(vcs_repo.value.branch, null)
      oauth_token_id             = try(vcs_repo.value.oauth_token_id, null)
      github_app_installation_id = try(vcs_repo.value.github_app_installation_id, null)
      ingress_submodules         = try(vcs_repo.value.ingress_submodules, false)
      tags_regex                 = try(vcs_repo.value.tags_regex, null)
    }
  }
}

resource "tfe_team" "this" {
  for_each = var.teams

  name                          = each.value.name
  sso_team_id                   = try(each.value.sso_team_id, null)
  visibility                    = try(each.value.visibility, "organization")
  allow_member_token_management = try(each.value.allow_member_token_management, false)
}

resource "tfe_team_access" "this" {
  for_each = var.workspace_team_access

  workspace_id = tfe_workspace.this[each.value.workspace_key].id
  team_id      = tfe_team.this[each.value.team_key].id
  access       = try(each.value.access, null)

  dynamic "permissions" {
    for_each = try(each.value.permissions, null) == null ? [] : [each.value.permissions]
    content {
      runs              = permissions.value.runs
      variables         = permissions.value.variables
      state_versions    = permissions.value.state_versions
      sentinel_mocks    = permissions.value.sentinel_mocks
      workspace_locking = permissions.value.workspace_locking
      run_tasks         = permissions.value.run_tasks
      policy_overrides  = try(permissions.value.policy_overrides, null)
    }
  }
}

resource "tfe_variable_set" "this" {
  for_each = var.variable_sets

  name              = each.value.name
  description       = try(each.value.description, null)
  global            = try(each.value.global, false)
  priority          = try(each.value.priority, false)
  parent_project_id = try(each.value.parent_project_key, null) == null ? null : tfe_project.this[each.value.parent_project_key].id
}

resource "tfe_workspace_variable_set" "this" {
  for_each = local.variable_set_workspace_attachments

  variable_set_id = tfe_variable_set.this[each.value.variable_set_key].id
  workspace_id    = tfe_workspace.this[each.value.workspace_key].id
}

resource "tfe_project_variable_set" "this" {
  for_each = local.variable_set_project_attachments

  variable_set_id = tfe_variable_set.this[each.value.variable_set_key].id
  project_id      = tfe_project.this[each.value.project_key].id
}

resource "tfe_variable" "variable_set" {
  for_each = local.variable_set_variables

  variable_set_id = tfe_variable_set.this[each.value.variable_set_key].id
  key             = each.value.key
  value           = try(each.value.value, null)
  category        = try(each.value.category, "terraform")
  description     = try(each.value.description, null)
  hcl             = try(each.value.hcl, false)
  sensitive       = try(each.value.sensitive, false)
}

resource "tfe_variable" "workspace" {
  for_each = local.workspace_variables

  workspace_id = tfe_workspace.this[each.value.workspace_key].id
  key          = each.value.key
  value        = try(each.value.value, null)
  category     = try(each.value.category, "terraform")
  description  = try(each.value.description, null)
  hcl          = try(each.value.hcl, false)
  sensitive    = try(each.value.sensitive, false)
}

resource "tfe_registry_module" "this" {
  for_each = var.registry_modules

  organization    = var.organization
  name            = each.value.name
  module_provider = each.value.module_provider
  registry_name   = try(each.value.registry_name, "private")
  namespace       = try(each.value.namespace, null)
  initial_version = try(each.value.initial_version, null)

  dynamic "vcs_repo" {
    for_each = try(each.value.vcs_repo, null) == null ? [] : [each.value.vcs_repo]
    content {
      identifier                 = vcs_repo.value.identifier
      branch                     = try(vcs_repo.value.branch, null)
      oauth_token_id             = try(vcs_repo.value.oauth_token_id, null)
      github_app_installation_id = try(vcs_repo.value.github_app_installation_id, null)
      tags                       = try(vcs_repo.value.tags, true)
      tag_prefix                 = try(vcs_repo.value.tag_prefix, null)
      source_directory           = try(vcs_repo.value.source_directory, null)
    }
  }

  dynamic "test_config" {
    for_each = try(each.value.test_config, null) == null ? [] : [each.value.test_config]
    content {
      tests_enabled        = try(test_config.value.tests_enabled, true)
      agent_execution_mode = try(test_config.value.agent_execution_mode, null)
      agent_pool_id        = try(test_config.value.agent_pool_id, null)
    }
  }
}

resource "tfe_policy_set" "this" {
  for_each = var.policy_sets

  name                   = each.value.name
  description            = try(each.value.description, null)
  kind                   = try(each.value.kind, "sentinel")
  global                 = try(each.value.global, false)
  workspace_ids          = try(each.value.global, false) ? null : [for key in try(each.value.workspace_keys, []) : tfe_workspace.this[key].id]
  policy_ids             = length(try(each.value.policy_ids, [])) == 0 ? null : each.value.policy_ids
  policies_path          = try(each.value.policies_path, null)
  policy_tool_version    = try(each.value.policy_tool_version, null)
  policy_update_patterns = try(each.value.policy_update_patterns, null)
  overridable            = try(each.value.overridable, false)
  agent_enabled          = try(each.value.agent_enabled, null)

  dynamic "vcs_repo" {
    for_each = try(each.value.vcs_repo, null) == null ? [] : [each.value.vcs_repo]
    content {
      identifier                 = vcs_repo.value.identifier
      branch                     = try(vcs_repo.value.branch, null)
      oauth_token_id             = try(vcs_repo.value.oauth_token_id, null)
      github_app_installation_id = try(vcs_repo.value.github_app_installation_id, null)
      ingress_submodules         = try(vcs_repo.value.ingress_submodules, false)
    }
  }
}

resource "tfe_run_trigger" "this" {
  for_each = var.run_triggers

  workspace_id  = tfe_workspace.this[each.value.workspace_key].id
  sourceable_id = tfe_workspace.this[each.value.source_workspace_key].id
}

module "operational_contracts" {
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-operational-contracts/azurerm"
  version = "1.0.0"

  contracts = var.operational_contracts
}
