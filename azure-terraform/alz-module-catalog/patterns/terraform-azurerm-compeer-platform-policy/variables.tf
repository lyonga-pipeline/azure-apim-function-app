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

variable "private_only_connectivity" {
  description = <<-EOT
    Optional built-in guardrail bundle that enforces Compeer's "private
    connectivity only, inbound via Cloudflare Tunnels" requirement. When
    `enabled`, the pattern adds two custom deny policies (no Public IP outside
    approved resource groups; no Public IP on NICs), an initiative, and a
    management-group assignment. Start with `effect = "Audit"`, review
    compliance, then flip to `"Deny"`.

    Built-in PaaS "disable public network access" policies are opt-in
    (`include_builtin_baseline = true` + `builtin_policy_definition_ids`) because
    their GUIDs must be verified against the tenant - see the pattern README.
  EOT
  type = object({
    enabled                                = optional(bool, false)
    management_group_key                   = optional(string)
    management_group_id                    = optional(string)
    effect                                 = optional(string, "Audit")
    enforce                                = optional(bool, true)
    allowed_public_ip_resource_group_names = optional(list(string), [])
    not_scopes                             = optional(list(string), [])
    include_builtin_baseline               = optional(bool, false)
    builtin_policy_definition_ids          = optional(map(string), {})
  })
  default = {}

  validation {
    condition     = try(var.private_only_connectivity.effect, "Audit") == null ? true : contains(["Audit", "Deny", "Disabled"], var.private_only_connectivity.effect)
    error_message = "private_only_connectivity.effect must be Audit, Deny, or Disabled."
  }

  validation {
    condition = (
      !try(var.private_only_connectivity.enabled, false) ? true :
      (try(var.private_only_connectivity.management_group_key, null) != null) != (try(var.private_only_connectivity.management_group_id, null) != null)
    )
    error_message = "When private_only_connectivity.enabled, set exactly one of management_group_key or management_group_id."
  }
}
