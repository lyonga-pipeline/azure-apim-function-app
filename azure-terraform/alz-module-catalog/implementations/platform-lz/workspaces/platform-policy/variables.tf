variable "tenant_id" {
  description = "Entra tenant ID. Provide via the shared HCP variable set as a Terraform-category variable named `tenant_id` - it is constant across the tenant. Do NOT set it in a .tfvars file or as an env var."
  type        = string
}

variable "execution_subscription_id" {
  description = "Target subscription ID for this workspace. Set it directly as a workspace-level Terraform-category variable in HCP (it differs per landing zone). Do NOT set it in a .tfvars file."
  type        = string
}

variable "location" {
  description = "Default Azure region for policy assignments that need a managed identity."
  type        = string
  default     = "centralus"
}

variable "use_tfe_outputs" {
  description = "Read approved governance outputs from HCP Terraform."
  type        = bool
  default     = true
}

variable "tfe_organization" {
  description = "HCP Terraform organization that contains the producer workspaces."
  type        = string
  default     = null
}

variable "governance_workspace_name" {
  description = "Workspace that publishes management_group_ids."
  type        = string
  default     = "platform-governance"
}

variable "management_workspace_name" {
  description = "Workspace that publishes subscription_id for the Defender exclusion and log_analytics_workspace_id for DINE remediation."
  type        = string
  default     = "platform-management"
}

variable "management_subscription_id" {
  description = "Optional management subscription UUID when its public workspace output is unavailable. Keeps that subscription excluded from fleet Defender DINE; must match the published subscription_id when both are available. This is not the policy execution subscription ID."
  type        = string
  default     = null

  validation {
    condition     = var.management_subscription_id == null ? true : can(regex("^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$", var.management_subscription_id))
    error_message = "management_subscription_id must be a subscription UUID, not a subscription resource path, name, or placeholder."
  }
}

variable "management_group_ids" {
  description = "Explicit management group IDs. These override or extend governance workspace outputs."
  type        = map(string)
  default     = {}
}

variable "policy" {
  description = "Policy workspace configuration: definitions, initiatives, and assignments."
  type        = any
  default = {
    enabled = false
  }
}
