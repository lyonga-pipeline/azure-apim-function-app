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
  description = "Deprecated compatibility input; ignored. The spoke uses only the workload provider and full existing-zone ARM IDs."
  type        = string
  default     = null
}
variable "private_dns_subscription_id" {
  description = "Deprecated compatibility input; ignored. A separate DNS provider/subscription context is no longer required."
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

variable "private_dns_zone_ids" {
  description = "Approved existing Azure Private DNS zone references, including manually created or legacy-owned zones. Supply through an HCP Terraform/HCL variable set or this root; no producer-workspace changes, zone creation or state adoption. Takes precedence over platform_inputs and connectivity outputs."
  type        = map(string)
  default     = {}
  validation {
    condition = length(setsubtract(toset(keys(var.private_dns_zone_ids)), toset(["key_vault", "storage_blob"]))) == 0 && alltrue([
      for key, id in var.private_dns_zone_ids : can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.Network/privateDnsZones/${key == "key_vault" ? "privatelink\\.vaultcore\\.azure\\.net" : "privatelink\\.blob\\.core\\.windows\\.net"}$", id))
    ])
    error_message = "Use only key_vault/storage_blob keys with full ARM IDs for their approved existing service zones."
  }
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

variable "environment" {
  description = "Approved non-production environment; production cannot be deployed from this workspace."
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "test", "uat", "np1", "np2", "np3"], var.environment)
    error_message = "The non-production workspace only accepts dev, test, uat, np1, np2 or np3."
  }
}
