variable "subscription_id" {
  type        = string
  description = "Execution subscription for governance deployment"
}

variable "root_management_group_id" {
  type        = string
  description = "Optional existing parent management group resource ID or name for top-level landing-zone management groups. Leave unset or blank to create them directly under the tenant root."
  default     = null

  validation {
    condition = (
      try(trimspace(var.root_management_group_id), "") == "" ||
      can(regex("^/providers/Microsoft\\.Management/managementGroups/[A-Za-z0-9_.()\\-]+$", var.root_management_group_id)) ||
      can(regex("^[A-Za-z0-9_.()\\-]+$", var.root_management_group_id))
    )
    error_message = "root_management_group_id must be unset, blank, a management group name like compeer-root, or a full Azure management group resource ID like /providers/Microsoft.Management/managementGroups/compeer-root."
  }
}

variable "management_groups" {
  type = map(object({
    display_name = string
    parent_key   = optional(string, "root")
  }))
  description = "Management groups keyed by stable purpose"
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
    name                                   = optional(string)
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

variable "policy_baseline" {
  description = <<-EOT
    Built-in Compeer deny/audit policy baseline (see policy_baseline.tf). When
    enabled, ships allowed-regions, required-tags, deny-public-PaaS,
    secure-storage, restrict-public-IP, private-SQL policies + the Microsoft
    Cloud Security Benchmark assignment, all at management_group_key.

    effect defaults to "Audit" - promote to "Deny" per policy after review.
  EOT
  type = object({
    enabled                   = optional(bool, false)
    management_group_key      = optional(string)
    effect                    = optional(string, "Audit")
    enforce                   = optional(bool, true)
    allowed_locations         = optional(list(string), ["centralus"])
    required_tag_names        = optional(list(string))
    assign_security_benchmark = optional(bool, true)
    not_scopes                = optional(list(string), [])
    # Resource groups carved out of deny-public-PaaS / secure-storage - the
    # documented exception path (e.g. the Palo Alto bootstrap RG). Keep short.
    exempt_resource_group_names = optional(list(string), [])
  })
  default = {}

  validation {
    condition     = try(var.policy_baseline.effect, "Audit") == null ? true : contains(["Audit", "Deny", "Disabled"], var.policy_baseline.effect)
    error_message = "policy_baseline.effect must be Audit, Deny, or Disabled."
  }

  validation {
    condition     = !try(var.policy_baseline.enabled, false) ? true : try(var.policy_baseline.management_group_key, null) != null
    error_message = "policy_baseline.enabled requires policy_baseline.management_group_key (the top landing-zone MG catalog key)."
  }
}
