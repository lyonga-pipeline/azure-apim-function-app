# =============================================================================
# PHASE 2 CHANGES - additive, opt-in; preserve existing resource/state ownership.
# Copy this file together with the PHASE 2 section in main.tf and the example.
# =============================================================================
variable "phase2_audit_initiatives" {
  type = map(object({
    name                     = string
    management_group_id      = string
    policy_set_definition_id = string
    parameters_json          = optional(string)
    approval_reference       = string
  }))
  default = {}
  validation {
    condition = alltrue([for item in values(var.phase2_audit_initiatives) :
      length(item.name) <= 24 && length(trimspace(item.approval_reference)) > 0 &&
      can(regex("^/providers/Microsoft.Management/managementGroups/[^/]+$", item.management_group_id)) &&
      can(regex("(?i)/providers/Microsoft.Authorization/policySetDefinitions/[^/]+$", item.policy_set_definition_id)) &&
      (item.parameters_json == null ? true : can(jsondecode(item.parameters_json)))
    ])
    error_message = "Audit initiatives need verified IDs, valid JSON parameters, an approved scope and assignment name <=24 characters."
  }
}

variable "phase2_exemptions" {
  type = map(object({
    name                            = string
    scope_type                      = string
    scope_id                        = string
    policy_assignment_id            = string
    policy_definition_reference_ids = optional(list(string))
    category                        = optional(string, "Waiver")
    justification                   = string
    approved_by                     = string
    ticket                          = string
    expires_on                      = string
  }))
  default = {}
  validation {
    condition = alltrue([for exemption in values(var.phase2_exemptions) :
      contains(["resource", "resource_group", "subscription"], exemption.scope_type) &&
      contains(["Waiver", "Mitigated"], exemption.category) &&
      alltrue([for value in [exemption.justification, exemption.approved_by, exemption.ticket] : length(trimspace(value)) > 0]) &&
      can(formatdate("YYYY-MM-DD", exemption.expires_on))
    ])
    error_message = "Exemptions need a narrow resource/RG/subscription scope, justification, named approver, ticket and valid expiry."
  }
}

variable "phase2_sandbox_scope" {
  type = object({
    management_group_id = string
    policy_name         = optional(string, "sandbox-expiry")
    effect              = optional(string, "Audit")
    approval_reference  = string
  })
  default = null
  validation {
    condition     = var.phase2_sandbox_scope == null ? true : contains(["Audit", "Deny"], var.phase2_sandbox_scope.effect) && length(trimspace(var.phase2_sandbox_scope.approval_reference)) > 0
    error_message = "Sandbox guardrails need approved scope/effect; start in Audit and explicitly approve Deny."
  }
}
