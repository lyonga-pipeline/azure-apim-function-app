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

variable "resource_group_policy_assignments" {
  type        = any
  description = "Resource-group-scoped Azure Policy assignments (exceptions, workload-specific guardrails)."
  default     = {}
}

variable "policy_exemptions" {
  description = <<-EOT
    Policy exemptions keyed by exemption name. Each: scope_type
    (management_group | subscription | resource_group), the matching scope id
    (or management_group_key), policy_assignment_id OR policy_assignment_key
    (a key into this pattern's own assignments), exemption_category
    (Waiver | Mitigated), optional expires_on, description,
    policy_definition_reference_ids.
  EOT
  type = map(object({
    scope_type                      = string
    management_group_id             = optional(string)
    management_group_key            = optional(string)
    subscription_id                 = optional(string)
    resource_group_id               = optional(string)
    policy_assignment_id            = optional(string)
    policy_assignment_key           = optional(string)
    exemption_category              = optional(string, "Waiver")
    display_name                    = optional(string)
    description                     = optional(string)
    expires_on                      = optional(string)
    metadata                        = optional(any)
    policy_definition_reference_ids = optional(list(string))
  }))
  default = {}

  validation {
    condition     = alltrue([for e in values(var.policy_exemptions) : contains(["management_group", "subscription", "resource_group"], e.scope_type)])
    error_message = "policy_exemptions[*].scope_type must be management_group, subscription, or resource_group."
  }

  validation {
    condition     = alltrue([for e in values(var.policy_exemptions) : contains(["Waiver", "Mitigated"], try(e.exemption_category, "Waiver"))])
    error_message = "policy_exemptions[*].exemption_category must be Waiver or Mitigated."
  }
}

variable "remediation" {
  description = <<-EOT
    Opt-in DeployIfNotExists / Modify remediation bundle (see remediation.tf).
    Assignments get a SystemAssigned identity + location and run at their own
    management_group_key (falling back to the bundle's key). Built-in policy/initiative IDs are caller-supplied
    (verify with `az policy definition list`). Existing-resource remediation
    tasks are explicitly opted in, not started automatically.
  EOT
  type = object({
    enabled                    = optional(bool, false)
    management_group_key       = optional(string)
    location                   = optional(string)
    log_analytics_workspace_id = optional(string)
    # Policy parameters are JSON-like and legitimately differ by built-in
    # definition. Keeping this keyed object dynamic avoids Terraform forcing
    # unrelated assignment parameter values into one common map element type.
    dine_assignments = optional(any, {})
    tasks = optional(map(object({
      assignment_key = string
      # Null preserves existing MG-scoped task addresses; an ID confines a backfill to one subscription.
      subscription_id                = optional(string)
      policy_definition_reference_id = optional(string)
      location_filters               = optional(list(string))
      resource_discovery_mode        = optional(string, "ExistingNonCompliant")
      resource_count                 = optional(number, 100)
      parallel_deployments           = optional(number, 5)
      failure_percentage             = optional(number, 0.1)
    })), {})
  })
  default = {}

  validation {
    condition = alltrue([
      for assignment in values(try(var.remediation.dine_assignments, {})) :
      length(compact([
        try(assignment.policy_definition_id, null),
        try(assignment.policy_definition_key, null),
        try(assignment.policy_set_definition_id, null),
        try(assignment.policy_set_definition_key, null)
      ])) == 1
    ])
    error_message = "Each remediation assignment must set exactly one policy definition/initiative ID or key."
  }


  validation {
    condition = alltrue([
      for assignment in values(try(var.remediation.dine_assignments, {})) :
      can(tobool(try(assignment.inject_law, false))) &&
      can(toset(try(assignment.role_definition_ids, [])))
    ])
    error_message = "Each remediation assignment must use a boolean inject_law value and a collection of role_definition_ids."
  }

  validation {
    condition = alltrue([for task in values(var.remediation.tasks) :
      task.resource_count >= 1 && task.resource_count <= 50000 && floor(task.resource_count) == task.resource_count &&
      task.parallel_deployments >= 1 && task.parallel_deployments <= 30 && floor(task.parallel_deployments) == task.parallel_deployments &&
      task.failure_percentage >= 0 && task.failure_percentage <= 1
    ])
    error_message = "Remediation tasks require integer resource_count 1-50000, integer parallel_deployments 1-30, and failure_percentage 0-1."
  }

  validation {
    condition = alltrue([for task in values(var.remediation.tasks) :
      task.subscription_id == null ? true : (
        can(regex("(?i)^/subscriptions/[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$", task.subscription_id)) &&
        lower(task.subscription_id) != "/subscriptions/00000000-0000-0000-0000-000000000000"
      )
    ])
    error_message = "A subscription-scoped task requires a nonzero full /subscriptions/<UUID> ID, not a display name or placeholder."
  }

  validation {
    condition = alltrue([for task in values(var.remediation.tasks) :
      contains(["ExistingNonCompliant", "ReEvaluateCompliance"], task.resource_discovery_mode) &&
      (task.subscription_id != null || task.resource_discovery_mode == "ExistingNonCompliant")
    ])
    error_message = "Use ExistingNonCompliant or ReEvaluateCompliance. AzureRM MG-scoped tasks support only ExistingNonCompliant; use a subscription task for a fresh scan."
  }
}
