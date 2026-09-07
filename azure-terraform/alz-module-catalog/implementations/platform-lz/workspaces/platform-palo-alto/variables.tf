variable "tenant_id" {
  description = "Entra tenant ID. Provide via the shared HCP variable set as a Terraform-category variable named `tenant_id` - it is constant across the tenant. Do NOT set it in a .tfvars file or as an env var."
  type        = string
}

variable "subscription_id" {
  description = "Target subscription ID for this workspace. Set it directly as a workspace-level Terraform-category variable in HCP (it differs per landing zone). Do NOT set it in a .tfvars file."
  type        = string
}

variable "location" {
  description = "Azure region for Palo Alto resources."
  type        = string
  default     = "centralus"
}

variable "use_tfe_outputs" {
  description = "Read approved hub networking outputs from the connectivity workspace."
  type        = bool
  default     = true
}

variable "tfe_organization" {
  description = "HCP Terraform organization that contains the producer workspaces."
  type        = string
  default     = null
}

variable "connectivity_workspace_name" {
  description = "Workspace that publishes hub subnet and resource group outputs."
  type        = string
  default     = "platform-connectivity"
}

variable "tags" {
  description = "Enterprise tags for Palo Alto resources."
  type        = map(string)
  default     = {}
}

variable "palo_alto" {
  description = "Palo Alto hub workspace configuration."
  type        = any
  default = {
    enabled = false
  }
}

variable "palo_alto_bootstrap_storage_keys" {
  description = "Sensitive bootstrap storage-account access keys keyed by firewall (palo_alto.virtual_machines key). Set only when a firewall points at an EXTERNAL bootstrap storage account (e.g. a phase-1 workspace output). Omit to use this pattern's own bootstrap storage."
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "environment" {
  description = "Environment token for Appendix F naming (prod | uat | test | dev | np | sandbox | shared)."
  type        = string
  default     = "prod"
}
