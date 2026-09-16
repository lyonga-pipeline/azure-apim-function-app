# =============================================================================
# PATTERN: subscription-onboarding
#
# Subscriptions at Compeer are provisioned by the CSP partner, NOT by Terraform.
# A new subscription lands under the Tenant Root Group. This pattern takes those
# already-existing subscription IDs and, per subscription:
#   1. moves it from the root group to its target management group, and
#   2. applies a consistent baseline RBAC set plus any app-specific RBAC, all at
#      subscription scope.
#
# Management-group creation and management-group-scope RBAC stay in the
# `global-governance` pattern. This pattern never creates subscriptions — see the
# retired `subscription-vending` pattern for that (not deployed).
# =============================================================================

variable "management_group_ids" {
  description = <<-EOT
    Resolved management group resource IDs keyed by a stable catalog key
    (typically the `management_group_ids` output of the governance workspace).
    Values may be a bare MG name or a full
    `/providers/Microsoft.Management/managementGroups/<name>` ID.
  EOT
  type        = map(string)
}

variable "root_management_group_id" {
  description = "Resource ID (or bare name) of the Tenant Root Group, used only for documentation/outputs. Subscriptions are assumed to currently sit here."
  type        = string
  default     = null
}

variable "subscriptions" {
  description = <<-EOT
    Already-existing subscriptions to onboard, keyed by a stable logical name.
    `subscription_id` is the GUID the CSP created. Exactly one of
    `target_management_group_key` or `target_management_group_id` must be set.
  EOT
  type = map(object({
    subscription_id             = string
    target_management_group_key = optional(string)
    target_management_group_id  = optional(string)
    display_name                = optional(string) # reference only; not enforced
    workload                    = optional(string, "Production")
    apply_baseline_rbac         = optional(bool, true)
    app_role_assignments = optional(map(object({
      name                             = optional(string)
      principal_id                     = optional(string)
      principal_group_key              = optional(string)
      role_definition_name             = optional(string)
      role_definition_id               = optional(string)
      principal_type                   = optional(string)
      description                      = optional(string)
      condition                        = optional(string)
      condition_version                = optional(string)
      skip_service_principal_aad_check = optional(bool)
    })), {})
  }))

  validation {
    condition = alltrue([
      for s in values(var.subscriptions) :
      can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", s.subscription_id))
    ])
    error_message = "Every subscriptions[*].subscription_id must be a subscription GUID (no /subscriptions/ prefix)."
  }

  validation {
    condition = alltrue([
      for s in values(var.subscriptions) :
      (s.target_management_group_key != null) != (s.target_management_group_id != null)
    ])
    error_message = "Each subscription must set exactly one of target_management_group_key or target_management_group_id."
  }

  validation {
    condition = alltrue([
      for s in values(var.subscriptions) :
      contains(["Production", "DevTest"], s.workload)
    ])
    error_message = "subscriptions[*].workload must be Production or DevTest."
  }

  validation {
    condition = alltrue(flatten([
      for s in values(var.subscriptions) : [
        for a in values(s.app_role_assignments) :
        (try(a.principal_id, null) != null) != (try(a.principal_group_key, null) != null)
      ]
    ]))
    error_message = "Each app_role_assignments entry must set exactly one of principal_id or principal_group_key."
  }

  validation {
    condition = alltrue(flatten([
      for s in values(var.subscriptions) : [
        for a in values(s.app_role_assignments) :
        (a.role_definition_name != null) != (a.role_definition_id != null)
      ]
    ]))
    error_message = "Each app_role_assignments entry must set exactly one of role_definition_name or role_definition_id."
  }

  validation {
    condition = alltrue(flatten([
      for s in values(var.subscriptions) : [
        for a in values(s.app_role_assignments) :
        try(a.principal_type, null) == null ? true : lower(a.principal_type) != "user"
      ]
    ]))
    error_message = "Direct User principals are not allowed for subscription onboarding RBAC. Use Entra groups, managed identities, or service principals."
  }
}

variable "baseline_role_assignments" {
  description = <<-EOT
    RBAC applied at subscription scope to EVERY onboarded subscription where
    `apply_baseline_rbac` is true — the consistent platform baseline (e.g.
    platform operations, security readers, break-glass). Keyed by a stable name.
  EOT
  type = map(object({
    role_definition_name             = optional(string)
    role_definition_id               = optional(string)
    principal_id                     = optional(string)
    principal_group_key              = optional(string)
    principal_type                   = optional(string)
    description                      = optional(string)
    condition                        = optional(string)
    condition_version                = optional(string)
    skip_service_principal_aad_check = optional(bool)
  }))
  default = {}

  validation {
    condition = alltrue([
      for a in values(var.baseline_role_assignments) :
      (try(a.principal_id, null) != null) != (try(a.principal_group_key, null) != null)
    ])
    error_message = "Each baseline_role_assignments entry must set exactly one of principal_id or principal_group_key."
  }

  validation {
    condition = alltrue([
      for a in values(var.baseline_role_assignments) :
      (a.role_definition_name != null) != (a.role_definition_id != null)
    ])
    error_message = "Each baseline_role_assignments entry must set exactly one of role_definition_name or role_definition_id."
  }

  validation {
    condition = alltrue([
      for a in values(var.baseline_role_assignments) :
      try(a.principal_type, null) == null ? true : lower(a.principal_type) != "user"
    ])
    error_message = "Direct User principals are not allowed for subscription onboarding RBAC. Use Entra groups, managed identities, or service principals."
  }
}

variable "legacy_policy_removals" {
  description = <<-EOT
    Subscription-scope (or resource-group-scope) policy ASSIGNMENTS to remove
    during onboarding — found by reviewing the CSP-handed-over subscription in
    the Portal before/during onboarding.

    Why this exists: moving a subscription to a new management group (below)
    automatically and immediately stops MG-inherited policies from the OLD
    parent/root from applying, and starts the NEW landing-zone MG's policies
    applying instead — that part is Azure's native behaviour, not something
    this pattern needs to do anything extra for. What Azure does NOT do on
    its own is remove a policy assignment that was made DIRECTLY at the
    subscription (or a resource group inside it) rather than inherited from
    an MG — that kind of assignment stays attached to the subscription
    regardless of which MG it moves under, and will keep evaluating
    alongside the new landing-zone baseline unless explicitly removed. This
    variable is how that removal happens, safely: each entry is imported
    into Terraform state (see the `import` blocks in main.tf) as a real
    `azurerm_subscription_policy_assignment` / `azurerm_resource_group_policy_assignment`,
    then intentionally left undeclared everywhere else, so the plan proposes
    destroying it — visible and reviewable before it happens, not implicit.

    `policy_definition_id` is the full resource ID of whatever the legacy
    assignment points to — a plain policy OR an initiative (Azure's API uses
    the same field for both; find it on the assignment's Portal "Definition"
    link).
  EOT
  type = map(object({
    subscription_key     = string
    scope_type           = string # "subscription" | "resource_group"
    resource_group_name  = optional(string)
    assignment_name      = string
    policy_definition_id = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for r in values(var.legacy_policy_removals) :
      contains(["subscription", "resource_group"], r.scope_type)
    ])
    error_message = "legacy_policy_removals[*].scope_type must be \"subscription\" or \"resource_group\"."
  }

  validation {
    condition = alltrue([
      for r in values(var.legacy_policy_removals) :
      r.scope_type != "resource_group" || try(r.resource_group_name, null) != null
    ])
    error_message = "legacy_policy_removals[*].resource_group_name is required when scope_type is \"resource_group\"."
  }

  # NOTE: cross-referencing var.subscriptions here is not possible - a variable
  # validation condition can only refer to the variable itself (Terraform <1.9
  # limit; this repo targets >= 1.5.0). That check lives instead as a
  # precondition on terraform_data.onboarding_contract in main.tf, alongside
  # the other cross-variable checks (unresolved_target_keys, etc.) that already
  # use that pattern for the same reason.
}

variable "group_object_ids" {
  description = "Entra security group object IDs keyed by platform-authorization rbac_groups key. Used to resolve principal_group_key for baseline and app subscription RBAC."
  type        = map(string)
  default     = {}
}

variable "default_tags" {
  description = "Tags recorded on the onboarding contract marker (informational; subscription tags are set by the owning workload)."
  type        = map(string)
  default     = {}
}
