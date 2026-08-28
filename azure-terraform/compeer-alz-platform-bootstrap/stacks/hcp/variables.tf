variable "tfe_hostname" {
  type    = string
  default = "app.terraform.io"
}
variable "organization_name" {
  description = "Existing HCP Terraform organization."
  type        = string
}
variable "ado_organization_name" {
  description = "ADO organization slug used by the existing HCP Azure DevOps VCS connection."
  type        = string
}
variable "ado_project_name" {
  description = "Existing ADO project containing the platform repositories."
  type        = string
}
variable "oauth_client_name" {
  description = "Existing HCP Terraform Azure DevOps OAuth/VCS connection name."
  type        = string
  default     = "Compeer Azure DevOps Services"
}
variable "project" {
  type = object({
    name        = string
    description = string
    tags        = optional(map(string), {})
  })
}
variable "repositories" {
  description = "Repository names created by the ADO stack. Kept as explicit configuration to avoid cross-state coupling."
  type = map(object({
    name = string
  }))
}
variable "workspaces" {
  type = map(object({
    name                  = string
    description           = string
    repository_key        = string
    working_directory     = string
    branch                = optional(string, "main")
    execution_mode        = optional(string, "agent")
    agent_pool_name       = optional(string)
    auto_apply            = optional(bool, false)
    speculative_enabled   = optional(bool, true)
    file_triggers_enabled = optional(bool, true)
    trigger_patterns      = optional(list(string), [])
    terraform_version     = string
    assessments_enabled   = optional(bool, true)
    tags                  = optional(map(string), {})
    variable_sets         = optional(list(string), [])
    terraform_variables = optional(map(object({
      value       = string
      description = optional(string, "")
      sensitive   = optional(bool, false)
      hcl         = optional(bool, false)
    })), {})
    environment_variables = optional(map(object({
      value       = string
      description = optional(string, "")
      sensitive   = optional(bool, false)
    })), {})
  }))
}
variable "variable_sets" {
  description = "New ALZ variable sets created and attached to the new HCP project."
  type = map(object({
    name        = string
    description = string
    priority    = optional(bool, false)
    variables = optional(map(object({
      value       = string
      category    = optional(string, "terraform")
      description = optional(string, "")
      sensitive   = optional(bool, false)
      hcl         = optional(bool, false)
    })), {})
  }))
  default = {}
}
variable "existing_project_variable_sets" {
  description = "Existing organization variable set names to attach to the new HCP project, if required."
  type        = set(string)
  default     = []
}
variable "opa_policy_set" {
  type = object({
    enabled                = optional(bool, true)
    name                   = string
    description            = string
    repository_key         = string
    branch                 = optional(string, "main")
    policies_path          = optional(string)
    overridable            = optional(bool, false)
    agent_enabled          = optional(bool, true)
    policy_tool_version    = optional(string)
    policy_update_patterns = optional(list(string), ["policies.hcl", "policies/**/*.rego"])
  })
}
