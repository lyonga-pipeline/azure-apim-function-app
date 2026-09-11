variable "policies" {
  description = <<-EOT
    PIM *activation policy* settings for a built-in/custom role at a scope —
    design doc Phase 2 Step 6 (approval, MFA-on-activation, max activation
    duration, notifications). Every Azure role at every scope already has an
    implicit default policy; this resource updates the existing one in place,
    it does not create a new object. Keyed by a caller-stable name.

    role_definition_id + scope together identify the (role, scope) pair whose
    policy is being edited — e.g. the same role_definition_id used in the
    matching terraform-azurerm-compeer-privileged-access
    pim_eligible_role_assignments entry.
  EOT
  type = map(object({
    role_definition_id = string
    scope              = string

    activation_rules = optional(object({
      maximum_duration                                   = optional(string)
      require_approval                                   = optional(bool)
      require_justification                              = optional(bool)
      require_multifactor_authentication                 = optional(bool)
      require_ticket_info                                = optional(bool)
      required_conditional_access_authentication_context = optional(string)
      approvers = optional(list(object({
        object_id = string
        type      = string # User or Group
      })), [])
    }))

    active_assignment_rules = optional(object({
      expiration_required                = optional(bool)
      expire_after                       = optional(string)
      require_justification              = optional(bool)
      require_multifactor_authentication = optional(bool)
      require_ticket_info                = optional(bool)
    }))

    eligible_assignment_rules = optional(object({
      expiration_required = optional(bool)
      expire_after        = optional(string)
    }))

    # One notification block per {rule_set}, each with up to 3 recipient roles.
    # rule_set: "active_assignments" | "eligible_activations" | "eligible_assignments"
    # recipient_role: "admin_notifications" | "approver_notifications" | "assignee_notifications"
    notification_rules = optional(map(map(object({
      default_recipients    = bool
      notification_level    = optional(string, "All") # All or Critical
      additional_recipients = optional(set(string), [])
    }))), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for p in values(var.policies) :
      alltrue([for rule_set in keys(p.notification_rules) : contains(["active_assignments", "eligible_activations", "eligible_assignments"], rule_set)])
    ])
    error_message = "notification_rules keys must be one of: active_assignments, eligible_activations, eligible_assignments."
  }

  validation {
    condition = alltrue([
      for p in values(var.policies) :
      alltrue([
        for rule_set, roles in p.notification_rules :
        alltrue([for role in keys(roles) : contains(["admin_notifications", "approver_notifications", "assignee_notifications"], role)])
      ])
    ])
    error_message = "notification_rules[*] keys must be one of: admin_notifications, approver_notifications, assignee_notifications."
  }
}
