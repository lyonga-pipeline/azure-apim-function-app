# =============================================================================
# PHASE 2 CHANGES - additive, opt-in; preserve existing resource/state ownership.
# Copy this file together with the PHASE 2 section in main.tf and the example.
# =============================================================================
variable "subscription_id" { type = string }
variable "location" {
  type    = string
  default = "centralus"
}
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
variable "ownership_confirmed" {
  description = "FinOps has reviewed existing management/onboarding budget ownership for this subscription."
  type        = bool
  default     = false
}
variable "existing_budget_names" {
  description = "Budget names retained in another state. Never duplicate these in the FinOps input."
  type        = set(string)
  default     = []
}
