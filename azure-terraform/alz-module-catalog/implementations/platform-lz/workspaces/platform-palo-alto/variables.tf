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

variable "palo_alto_vendor_vmseries_passwords" {
  description = "Sensitive VM-Series admin passwords keyed by palo_alto.vendor_vmseries key."
  type        = map(string)
  sensitive   = true
  default     = {}
}
