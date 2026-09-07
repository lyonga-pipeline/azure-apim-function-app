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
  description = "Workspace that publishes log_analytics_workspace_id (used by DINE remediation)."
  type        = string
  default     = "platform-management"
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
