variable "subscription_id" {
  description = "Workload subscription UUID, provided through HCP Terraform variables."
  type        = string
  default     = null
}
variable "tenant_id" {
  description = "Tenant UUID from the shared HCP variable set."
  type        = string
  default     = null
}
variable "connectivity_subscription_id" {
  description = "Compatibility fallback for private_dns_subscription_id only. No hub provider or peering write permission is used by the spoke."
  type        = string
  default     = null
}
variable "private_dns_subscription_id" {
  description = "Actual existing private-DNS subscription UUID; null uses connectivity_subscription_id."
  type        = string
  default     = null
}
variable "tfe_organization" {
  description = "Actual HCP Terraform organization."
  type        = string
  default     = null
}
variable "management_workspace_name" {
  description = "HCP producer workspace for central LAW public outputs."
  type        = string
  default     = "platform-management"
}
variable "connectivity_workspace_name" {
  description = "HCP producer workspace for hub/private-DNS public outputs."
  type        = string
  default     = "platform-connectivity"
}
variable "use_tfe_outputs" {
  description = "Read approved non-sensitive platform outputs; false requires explicit platform_inputs."
  type        = bool
  default     = true
}
variable "governance_workspace_name" {
  description = "HCP producer of approved mandatory tag keys; subscription onboarding stays with governance."
  type        = string
  default     = "platform-governance"
}
variable "platform_inputs" {
  description = "Explicit approved public-contract values, useful for an isolated integration environment."
  type        = any
  default     = {}
}
variable "spoke" {
  description = "Deployment configuration. Keep enabled=false until all placeholders and IPAM approvals are resolved."
  type        = any
  default     = { enabled = false }
  validation {
    condition     = !can(var.spoke.operations.budget)
    error_message = "operations.budget was removed from this Phase 1 package. Remove the legacy input; manage Phase 2 budgets separately with the governance owner."
  }
}
