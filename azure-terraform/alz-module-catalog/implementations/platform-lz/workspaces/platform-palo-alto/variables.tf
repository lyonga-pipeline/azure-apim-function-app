variable "tenant_id" {
  description = "Microsoft Entra tenant ID used by the Palo Alto workspace."
  type        = string
}

variable "subscription_id" {
  description = "Connectivity subscription ID containing the Palo Alto hub resources."
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
