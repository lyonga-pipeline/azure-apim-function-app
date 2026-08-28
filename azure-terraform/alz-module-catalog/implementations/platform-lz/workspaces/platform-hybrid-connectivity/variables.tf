variable "tenant_id" {
  description = "Microsoft Entra tenant ID used by the hybrid connectivity workspace."
  type        = string
}

variable "subscription_id" {
  description = "Hybrid/connectivity subscription ID."
  type        = string
}

variable "location" {
  description = "Azure region for hybrid connectivity resources."
  type        = string
  default     = "centralus"
}

variable "environment" {
  description = "Environment label used in names and tags."
  type        = string
  default     = "prod"
}

variable "platform_tags" {
  description = "Enterprise tag contract for hybrid connectivity resources."
  type = object({
    application         = string
    business_owner      = string
    source_repo         = string
    terraform_workspace = string
    recovery_tier       = string
    cost_center         = string
    data_classification = string
    compliance_boundary = string
    additional_tags     = optional(map(string), {})
  })
}

variable "use_tfe_outputs" {
  description = "Read approved hub subnet outputs from the connectivity workspace."
  type        = bool
  default     = true
}

variable "tfe_organization" {
  description = "HCP Terraform organization that contains the producer workspaces."
  type        = string
  default     = null
}

variable "connectivity_workspace_name" {
  description = "Workspace that publishes hub subnet outputs."
  type        = string
  default     = "platform-connectivity"
}

variable "hybrid_connectivity" {
  description = "Hybrid connectivity workspace configuration."
  type        = any
  default = {
    enabled = false
  }
}
