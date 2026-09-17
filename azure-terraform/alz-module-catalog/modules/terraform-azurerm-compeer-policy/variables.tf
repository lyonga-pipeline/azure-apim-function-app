# =============================================================================
# Scope boundary: every *_id field on every variable here is a CONCRETE,
# already-resolved Azure resource ID. This module has no concept of a
# management-group/subscription "catalog key" - resolving an abstract key
# (e.g. management_group_key = "corp") into a real resource ID is the calling
# pattern's job, because that catalog lives outside this module's own
# resource graph. The one exception is *_key fields that point at a sibling
# definition/initiative/assignment THIS MODULE ALSO CREATES in the same call
# (policy_definition_key, policy_set_definition_key, policy_assignment_key) -
# those stay here because the referenced ID is a computed value this module
# produces, not something the caller could resolve up front.
#
# Every map variable below is typed `any`, not a strict map(object(...)) -
# real Azure Policy `parameters` / `policy_rule` / `metadata` genuinely have
# a DIFFERENT attribute key set per policy (cmp-allowed-locations' parameters
# aren't shaped like cmp-required-tags'), and HCL's type-unification for a
# map built across multiple entries can't find one common object type when
# entries differ structurally - only `any` avoids that (this matches how the
# calling patterns already type their own equivalent variables, for the same
# reason). Validation blocks below still enforce the real contract via
# try()/alltrue(), which works identically against `any`.
# =============================================================================

variable "policy_definitions" {
  description = <<-EOT
    Custom Azure Policy definitions keyed by logical name. Each entry:
    display_name (required), management_group_id (required, concrete),
    policy_rule (required), and optional name, policy_type, mode,
    description, metadata, parameters.
  EOT
  type        = any
  default     = {}
}

variable "policy_set_definitions" {
  description = <<-EOT
    Policy initiatives (policy set definitions) keyed by logical name. Each
    entry: display_name (required), management_group_id (required,
    concrete), policy_definition_references (required list; each points at
    a sibling entry in var.policy_definitions via policy_definition_key, or
    at any existing policy/initiative via policy_definition_id), and
    optional name, policy_type, description, metadata, parameters.
  EOT
  type        = any
  default     = {}
}

variable "management_group_assignments" {
  description = <<-EOT
    Management-group-scoped policy or initiative assignments keyed by
    logical name. Each entry: management_group_id (required, concrete),
    exactly one of policy_definition_id / policy_definition_key /
    policy_set_definition_id / policy_set_definition_key, and optional
    name, display_name, description, enforce, location, parameters,
    not_scopes, identity ({type, identity_ids}), non_compliance_messages
    (map of {content, policy_definition_reference_id}).
  EOT
  type        = any
  default     = {}

  validation {
    condition = alltrue([
      for a in values(var.management_group_assignments) :
      length(compact([
        try(a.policy_definition_id, null), try(a.policy_definition_key, null),
        try(a.policy_set_definition_id, null), try(a.policy_set_definition_key, null),
      ])) == 1
    ])
    error_message = "Each management_group_assignments entry must set exactly one of policy_definition_id, policy_definition_key, policy_set_definition_id, or policy_set_definition_key."
  }
}

variable "subscription_assignments" {
  description = <<-EOT
    Subscription-scoped policy or initiative assignments keyed by logical
    name. Same shape as management_group_assignments, with subscription_id
    (required, concrete) instead of management_group_id.
  EOT
  type        = any
  default     = {}

  validation {
    condition = alltrue([
      for a in values(var.subscription_assignments) :
      length(compact([
        try(a.policy_definition_id, null), try(a.policy_definition_key, null),
        try(a.policy_set_definition_id, null), try(a.policy_set_definition_key, null),
      ])) == 1
    ])
    error_message = "Each subscription_assignments entry must set exactly one of policy_definition_id, policy_definition_key, policy_set_definition_id, or policy_set_definition_key."
  }
}

variable "resource_group_assignments" {
  description = <<-EOT
    Resource-group-scoped policy or initiative assignments keyed by logical
    name. Same shape as management_group_assignments, with
    resource_group_id (required, concrete) instead of management_group_id.
  EOT
  type        = any
  default     = {}

  validation {
    condition = alltrue([
      for a in values(var.resource_group_assignments) :
      length(compact([
        try(a.policy_definition_id, null), try(a.policy_definition_key, null),
        try(a.policy_set_definition_id, null), try(a.policy_set_definition_key, null),
      ])) == 1
    ])
    error_message = "Each resource_group_assignments entry must set exactly one of policy_definition_id, policy_definition_key, policy_set_definition_id, or policy_set_definition_key."
  }
}

variable "exemptions" {
  description = <<-EOT
    Policy exemptions keyed by exemption name. policy_assignment_key resolves
    against an assignment this SAME module call also creates (any of the
    three assignment scopes above); policy_assignment_id is for an
    assignment created elsewhere. Use exemptions sparingly and set
    expires_on.
  EOT
  type        = any
  default     = {}

  validation {
    condition     = alltrue([for e in values(var.exemptions) : contains(["management_group", "subscription", "resource_group"], e.scope_type)])
    error_message = "exemptions[*].scope_type must be management_group, subscription, or resource_group."
  }

  validation {
    condition     = alltrue([for e in values(var.exemptions) : contains(["Waiver", "Mitigated"], try(e.exemption_category, "Waiver"))])
    error_message = "exemptions[*].exemption_category must be Waiver or Mitigated."
  }

  validation {
    condition = alltrue([
      for e in values(var.exemptions) :
      (try(e.policy_assignment_id, null) != null) != (try(e.policy_assignment_key, null) != null)
    ])
    error_message = "Each exemptions entry must set exactly one of policy_assignment_id or policy_assignment_key."
  }

  validation {
    condition     = alltrue([for e in values(var.exemptions) : e.scope_type != "management_group" || try(e.management_group_id, null) != null])
    error_message = "exemptions[*].management_group_id is required when scope_type is \"management_group\"."
  }

  validation {
    condition     = alltrue([for e in values(var.exemptions) : e.scope_type != "subscription" || try(e.subscription_id, null) != null])
    error_message = "exemptions[*].subscription_id is required when scope_type is \"subscription\"."
  }

  validation {
    condition     = alltrue([for e in values(var.exemptions) : e.scope_type != "resource_group" || try(e.resource_group_id, null) != null])
    error_message = "exemptions[*].resource_group_id is required when scope_type is \"resource_group\"."
  }
}
