variable "subscription_id" {
  type        = string
  description = "Execution subscription for governance deployment."
}

variable "root_management_group_id" {
  type        = string
  description = "Tenant root management group id or approved Compeer root management group id."
}

variable "management_groups" {
  type = map(object({
    display_name = string
    parent_key   = optional(string, "root")
  }))
  description = "Management groups keyed by stable purpose."
}

variable "subscription_placements" {
  type = map(object({
    subscription_id      = string
    management_group_key = string
  }))
  description = "Subscriptions placed under the landing-zone management group hierarchy."
  default     = {}
}

variable "policy_assignment_location" {
  type        = string
  description = "Default location used by policy assignments that require a managed identity."
  default     = "eastus2"
}

variable "custom_policy_definitions" {
  type        = any
  description = "Custom Azure Policy definitions created at a management-group scope."
  default     = {}
}

variable "custom_policy_set_definitions" {
  type        = any
  description = "Custom Azure Policy initiative definitions created at a management-group scope."
  default     = {}
}

variable "management_group_policy_assignments" {
  type        = any
  description = "Management-group Azure Policy assignments for landing-zone guardrails."
  default     = {}

  validation {
    condition = alltrue([
      for assignment in values(var.management_group_policy_assignments) :
      length(compact([
        try(assignment.policy_definition_id, null),
        try(assignment.policy_definition_key, null),
        try(assignment.policy_set_definition_id, null),
        try(assignment.policy_set_definition_key, null)
      ])) == 1
    ])
    error_message = "Each management group policy assignment must set exactly one of policy_definition_id, policy_definition_key, policy_set_definition_id, or policy_set_definition_key."
  }
}

variable "subscription_policy_assignments" {
  type        = any
  description = "Subscription-level Azure Policy assignments for exceptions or platform-specific guardrails."
  default     = {}

  validation {
    condition = alltrue([
      for assignment in values(var.subscription_policy_assignments) :
      length(compact([
        try(assignment.policy_definition_id, null),
        try(assignment.policy_definition_key, null),
        try(assignment.policy_set_definition_id, null),
        try(assignment.policy_set_definition_key, null)
      ])) == 1
    ])
    error_message = "Each subscription policy assignment must set exactly one of policy_definition_id, policy_definition_key, policy_set_definition_id, or policy_set_definition_key."
  }
}

variable "custom_role_definitions" {
  type = map(object({
    name                 = string
    management_group_key = optional(string)
    scope                = optional(string)
    description          = optional(string)
    role_definition_id   = optional(string)
    assignable_scopes    = optional(list(string))
    permissions = map(object({
      actions          = optional(list(string), [])
      not_actions      = optional(list(string), [])
      data_actions     = optional(set(string), [])
      not_data_actions = optional(set(string), [])
    }))
  }))
  description = "Custom least-privilege platform role definitions."
  default     = {}
}

variable "role_assignments" {
  type = map(object({
    management_group_key                   = optional(string)
    scope                                  = optional(string)
    principal_id                           = string
    role_definition_name                   = optional(string)
    role_definition_id                     = optional(string)
    principal_type                         = optional(string)
    description                            = optional(string)
    condition                              = optional(string)
    condition_version                      = optional(string)
    skip_service_principal_aad_check       = optional(bool)
    delegated_managed_identity_resource_id = optional(string)
  }))
  description = "Management-group or explicit-scope RBAC assignments."
  default     = {}

  validation {
    condition = alltrue([
      for assignment in values(var.role_assignments) :
      (
        (try(assignment.scope, null) != null || try(assignment.management_group_key, null) != null) &&
        !(try(assignment.scope, null) != null && try(assignment.management_group_key, null) != null)
      )
    ])
    error_message = "Each role assignment must set exactly one of scope or management_group_key."
  }
}

variable "management_group_budgets" {
  type = map(object({
    management_group_key = string
    amount               = number
    time_grain           = string
    time_period = object({
      start_date = string
      end_date   = optional(string)
    })
    notifications = map(object({
      enabled        = optional(bool, true)
      threshold      = number
      operator       = string
      threshold_type = optional(string, "Actual")
      contact_emails = optional(list(string))
    }))
  }))
  description = "Management-group FinOps budget guardrails."
  default     = {}
}
