variable "organization" {
  description = "HCP Terraform organization name."
  type        = string
}

variable "projects" {
  description = "HCP Terraform projects for platform, workload, sandbox, and module delivery."
  type = map(object({
    name                           = string
    description                    = optional(string)
    auto_destroy_activity_duration = optional(string)
    tags                           = optional(map(string), {})
  }))
  default = {}
}

variable "workspaces" {
  description = "HCP Terraform workspaces for ALZ stack state, run settings, VCS wiring, and output contracts."
  type = map(object({
    name                                 = string
    project_key                          = optional(string)
    description                          = optional(string)
    working_directory                    = optional(string)
    terraform_version                    = optional(string)
    auto_apply                           = optional(bool, false)
    auto_apply_run_trigger               = optional(bool, false)
    allow_destroy_plan                   = optional(bool, false)
    assessments_enabled                  = optional(bool, true)
    queue_all_runs                       = optional(bool, true)
    speculative_enabled                  = optional(bool, true)
    file_triggers_enabled                = optional(bool, true)
    trigger_prefixes                     = optional(list(string))
    trigger_patterns                     = optional(list(string))
    tag_names                            = optional(set(string), [])
    tags                                 = optional(map(string), {})
    remote_state_consumer_workspace_keys = optional(list(string), [])
    global_remote_state                  = optional(bool, false)
    vcs_repo = optional(object({
      identifier                 = string
      branch                     = optional(string)
      oauth_token_id             = optional(string)
      github_app_installation_id = optional(string)
      ingress_submodules         = optional(bool, false)
      tags_regex                 = optional(string)
    }))
    variables = optional(map(object({
      key         = string
      value       = optional(string)
      category    = optional(string, "terraform")
      description = optional(string)
      hcl         = optional(bool, false)
      sensitive   = optional(bool, false)
    })), {})
  }))
  default = {}
}

variable "teams" {
  description = "HCP Terraform teams mapped to Entra SSO groups."
  type = map(object({
    name                          = string
    sso_team_id                   = optional(string)
    visibility                    = optional(string, "organization")
    allow_member_token_management = optional(bool, false)
  }))
  default = {}
}

variable "workspace_team_access" {
  description = "Workspace-level HCP Terraform RBAC."
  type = map(object({
    workspace_key = string
    team_key      = string
    access        = optional(string)
    permissions = optional(object({
      runs              = string
      variables         = string
      state_versions    = string
      sentinel_mocks    = string
      workspace_locking = bool
      run_tasks         = bool
      policy_overrides  = optional(bool)
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for access in values(var.workspace_team_access) :
      (try(access.access, null) != null) != (try(access.permissions, null) != null)
    ])
    error_message = "Each workspace_team_access entry must set exactly one of access or permissions."
  }
}

variable "variable_sets" {
  description = "Shared HCP Terraform variable sets and their workspace/project attachments."
  type = map(object({
    name               = string
    description        = optional(string)
    global             = optional(bool, false)
    priority           = optional(bool, false)
    parent_project_key = optional(string)
    workspace_keys     = optional(list(string), [])
    project_keys       = optional(list(string), [])
    variables = optional(map(object({
      key         = string
      value       = optional(string)
      category    = optional(string, "terraform")
      description = optional(string)
      hcl         = optional(bool, false)
      sensitive   = optional(bool, false)
    })), {})
  }))
  default = {}
}

variable "registry_modules" {
  description = "Private registry module declarations for Compeer HCP modules."
  type = map(object({
    name            = string
    module_provider = string
    registry_name   = optional(string, "private")
    namespace       = optional(string)
    initial_version = optional(string)
    vcs_repo = optional(object({
      identifier                 = string
      branch                     = optional(string)
      oauth_token_id             = optional(string)
      github_app_installation_id = optional(string)
      tags                       = optional(bool, true)
      tag_prefix                 = optional(string)
      source_directory           = optional(string)
    }))
    test_config = optional(object({
      tests_enabled        = optional(bool, true)
      agent_execution_mode = optional(string)
      agent_pool_id        = optional(string)
    }))
  }))
  default = {}
}

variable "policy_sets" {
  description = "Sentinel/OPA policy sets attached to HCP Terraform workspaces."
  type = map(object({
    name                   = string
    description            = optional(string)
    kind                   = optional(string, "sentinel")
    global                 = optional(bool, false)
    workspace_keys         = optional(list(string), [])
    policy_ids             = optional(set(string), [])
    policies_path          = optional(string)
    policy_tool_version    = optional(string)
    policy_update_patterns = optional(list(string))
    overridable            = optional(bool, false)
    agent_enabled          = optional(bool)
    vcs_repo = optional(object({
      identifier                 = string
      branch                     = optional(string)
      oauth_token_id             = optional(string)
      github_app_installation_id = optional(string)
      ingress_submodules         = optional(bool, false)
    }))
  }))
  default = {}
}

variable "run_triggers" {
  description = "Workspace run triggers for platform output contracts and environment promotion."
  type = map(object({
    workspace_key        = string
    source_workspace_key = string
  }))
  default = {}
}

variable "operational_contracts" {
  description = "Manual or bootstrap ALZ delivery controls tracked beside HCP Terraform configuration."
  type = map(object({
    phase                = optional(string, "Phase 1")
    owner                = optional(string)
    enabled              = optional(bool, false)
    cost_disabled        = optional(bool, true)
    implementation_state = optional(string, "contract-only")
    required_controls    = optional(list(string), [])
    evidence_locations   = optional(list(string), [])
    notes                = optional(string)
  }))
  default = {
    azure_devops_bootstrap = {
      phase                = "Phase 1"
      implementation_state = "manual-bootstrap"
      required_controls    = ["Azure DevOps project administrator approval", "first repo and service connection reconciled after creation"]
      notes                = "IAC-02 and IAC-05 start as bootstrap workflow and pipeline YAML; subsequent configuration should be brought under provider control."
    }
    hcp_bootstrap_workspace = {
      phase                = "Phase 1"
      implementation_state = "manual-bootstrap"
      required_controls    = ["HCP Terraform organization owner access", "VCS connection established before module publication"]
      notes                = "The first workspace and VCS OAuth/App connection are a bootstrap prerequisite for IAC-01/IAC-04."
    }
  }
}
