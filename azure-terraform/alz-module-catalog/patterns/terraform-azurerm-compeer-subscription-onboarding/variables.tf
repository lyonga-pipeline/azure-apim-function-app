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
      principal_id                     = string
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
        (a.role_definition_name != null) != (a.role_definition_id != null)
      ]
    ]))
    error_message = "Each app_role_assignments entry must set exactly one of role_definition_name or role_definition_id."
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
    principal_id                     = string
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
      (a.role_definition_name != null) != (a.role_definition_id != null)
    ])
    error_message = "Each baseline_role_assignments entry must set exactly one of role_definition_name or role_definition_id."
  }
}

variable "default_tags" {
  description = "Tags recorded on the onboarding contract marker (informational; subscription tags are set by the owning workload)."
  type        = map(string)
  default     = {}
}
