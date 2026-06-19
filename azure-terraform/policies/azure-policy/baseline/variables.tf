variable "subscription_id" {
  type        = string
  description = "Execution subscription for policy deployment."
}

variable "definition_management_group_id" {
  type        = string
  description = "Management group where custom policy definitions and initiatives are created."
}

variable "assignment_management_group_ids" {
  type        = map(string)
  description = "Management groups that receive the landing-zone baseline initiative."
  default     = {}
}

variable "organization_prefix" {
  type        = string
  description = "Short prefix used for policy resource names."
  default     = "compeer"
}

variable "allowed_locations" {
  type        = list(string)
  description = "Allowed Azure regions."
}

variable "required_tags" {
  type        = list(string)
  description = "Required enterprise tags."
  default = [
    "env",
    "application",
    "bt_owner",
    "source_repo",
    "tf_workspace",
    "recovery",
    "cost_center",
    "data_classification",
    "compliance_boundary",
  ]
}

variable "policy_effects" {
  type = object({
    allowed_locations          = optional(string, "Audit")
    required_tag               = optional(string, "Audit")
    deny_public_ip             = optional(string, "Audit")
    storage_public_network     = optional(string, "Audit")
    key_vault_public_network   = optional(string, "Audit")
    sql_public_network         = optional(string, "Audit")
    app_service_public_network = optional(string, "Audit")
  })
  default = {}

  validation {
    condition = alltrue([
      for effect in values(var.policy_effects) : contains(["Audit", "Deny", "Disabled"], effect)
    ])
    error_message = "Policy effects must be Audit, Deny, or Disabled."
  }
}

variable "assignment_location" {
  type        = string
  description = "Location used for policy assignment managed identities."
  default     = "eastus2"
}

