terraform {
  required_version = ">= 1.11.4, < 2.0.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = ">= 4.81.0, < 5.0.0" }
  }
}
variable "subscription_id" { type = string }
variable "policies" {
  description = "Approved existing Key Vault built-in policy IDs and exact parameters. Prefer existing central assignments; never assign duplicate DINE ownership."
  type        = map(object({ name = string, definition_id = string, parameters = string, enforce = optional(bool, false) }))
  default     = {}
  validation {
    condition     = alltrue([for item in values(var.policies) : try(contains(["Audit", "AuditIfNotExists", "Deny", "Disabled"], jsondecode(item.parameters).effect.value), false)])
    error_message = "Supply explicit Audit/AuditIfNotExists/Deny/Disabled effects; DINE/Modify assignments remain centrally owned with their identity and remediation roles."
  }
}
resource "azurerm_subscription_policy_assignment" "vault" {
  for_each             = var.policies
  name                 = each.value.name
  subscription_id      = var.subscription_id
  policy_definition_id = each.value.definition_id
  parameters           = each.value.parameters
  enforce              = each.value.enforce
  non_compliance_message { content = "Key Vault lifecycle baseline: RBAC, recovery, private connectivity and approved expiry/rotation policy are required." }
}
