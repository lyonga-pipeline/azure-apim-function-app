variable "tenant_id" {
  description = "Microsoft Entra tenant ID used by the connectivity workspace."
  type        = string
}

variable "subscription_id" {
  description = "Connectivity subscription ID."
  type        = string
}

variable "location" {
  description = "Azure region for connectivity resources."
  type        = string
  default     = "centralus"
}

variable "environment" {
  description = "Environment label used in names and tags."
  type        = string
  default     = "prod"
}

variable "platform_tags" {
  description = "Enterprise tag contract for connectivity resources."
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
  description = "Read approved outputs from the management workspace."
  type        = bool
  default     = true
}

variable "tfe_organization" {
  description = "HCP Terraform organization that contains the producer workspaces."
  type        = string
  default     = null
}

variable "management_workspace_name" {
  description = "Workspace that publishes Log Analytics and platform storage outputs."
  type        = string
  default     = "platform-management"
}

variable "log_analytics_workspace_id" {
  description = "Explicit Log Analytics workspace ID. Overrides management workspace output when set."
  type        = string
  default     = null
}

variable "connectivity" {
  description = "Platform connectivity workspace configuration."
  type        = any
  default = {
    enabled = false
  }
}
