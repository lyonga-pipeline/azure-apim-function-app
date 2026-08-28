variable "subscription_id" {
  type        = string
  description = "Execution subscription for policy deployment."
}

variable "management_group_ids" {
  type        = map(string)
  description = "Management group resource IDs keyed by governance catalog key."
  default     = {}
}

variable "policy_assignment_location" {
  type        = string
  description = "Default location used by policy assignments that require a managed identity."
  default     = "centralus"
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
