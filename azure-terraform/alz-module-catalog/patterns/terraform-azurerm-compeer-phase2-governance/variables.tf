variable "subscription_id" { type = string }
variable "location" {
  type    = string
  default = "centralus"
}
# PHASE2 NEW: v5 3.4 GOV-08. Caller supplies verified built-ins; no claim that FCA/GLBA are Azure initiatives.
variable "audit_initiatives" {
  type = map(object({
    name                     = string
    management_group_id      = string
    policy_set_definition_id = string
    parameters_json          = optional(string)
    approval_reference       = string
  }))
  default = {}
  validation {
    condition = alltrue([for item in values(var.audit_initiatives) :
      length(item.name) <= 24 && length(trimspace(item.approval_reference)) > 0 &&
      can(regex("^/providers/Microsoft.Management/managementGroups/[^/]+$", item.management_group_id)) &&
      can(regex("(?i)/providers/Microsoft.Authorization/policySetDefinitions/[^/]+$", item.policy_set_definition_id)) &&
      (item.parameters_json == null ? true : can(jsondecode(item.parameters_json)))
    ])
    error_message = "Audit initiatives need verified IDs, valid JSON parameters, an approved scope and assignment name <=24 characters."
  }
}
# PHASE2 NEW: v5 3.6 GOV-11. Narrow, approved and expiring; does not alter legacy exemption inputs.
variable "exemptions" {
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
    condition = alltrue([for exemption in values(var.exemptions) :
      contains(["resource", "resource_group", "subscription"], exemption.scope_type) &&
      contains(["Waiver", "Mitigated"], exemption.category) &&
      alltrue([for value in [exemption.justification, exemption.approved_by, exemption.ticket] : length(trimspace(value)) > 0]) &&
      can(formatdate("YYYY-MM-DD", exemption.expires_on))
    ])
    error_message = "Exemptions need a narrow resource/RG/subscription scope, justification, named approver, ticket and valid expiry."
  }
}
# PHASE2 NEW: v5 9.2 GOV-13 and 10.3 GOV-14; NOT a spoke blueprint budget.
variable "budgets" {
  type = map(object({
    name               = string
    amount             = number
    start_date         = string
    end_date           = string
    contact_emails     = set(string)
    contact_groups     = optional(set(string), [])
    approval_reference = string
  }))
  default = {}
  validation {
    condition     = alltrue([for budget in values(var.budgets) : budget.amount > 0 && length(budget.contact_emails) > 0 && length(trimspace(budget.approval_reference)) > 0])
    error_message = "Budgets require a positive FinOps-approved amount, approval reference and recipients."
  }
}
variable "cost_exports" {
  type = map(object({
    name                    = string
    container_id            = string
    root_folder_path        = string
    start_date              = string
    end_date                = string
    export_access_confirmed = bool
    cost_type               = optional(string, "ActualCost")
  }))
  default = {}
  validation {
    condition     = alltrue([for export in values(var.cost_exports) : export.export_access_confirmed && contains(["ActualCost", "AmortizedCost", "Usage"], export.cost_type)])
    error_message = "Cost export needs an approved accessible destination and supported cost type; existing storage/RBAC stays with its owner."
  }
}
variable "cost_anomalies" {
  type    = map(object({ name = string, email_addresses = set(string) }))
  default = {}
}
# PHASE2 NEW: v5 10.3 GOV-14. Require caller-supplied expiry, never mutate Terraform-owned tags.
variable "sandbox_scope" {
  type = object({
    management_group_id = string
    policy_name         = optional(string, "sandbox-expiry")
    effect              = optional(string, "Audit")
    approval_reference  = string
  })
  default = null
  validation {
    condition     = var.sandbox_scope == null ? true : contains(["Audit", "Deny"], var.sandbox_scope.effect) && length(trimspace(var.sandbox_scope.approval_reference)) > 0
    error_message = "Sandbox guardrails need approved scope/effect; start in Audit and explicitly approve Deny."
  }
}
