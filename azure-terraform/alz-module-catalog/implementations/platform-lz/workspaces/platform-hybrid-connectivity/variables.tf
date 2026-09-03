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
    application           = optional(string)
    owner                 = optional(string)
    source_repo           = optional(string)
    created_on            = optional(string)
    criticality_tier      = optional(string)
    data_classification   = optional(string)
    lifecycle_state       = optional(string)
    cost_center           = optional(string)
    gl_category           = optional(string)
    application_component = optional(string)
    modified_on           = optional(string)
    created_by            = optional(string)
    dr_tier               = optional(string)
    expiration_date       = optional(string)
    additional_tags       = optional(map(string), {})
  })
  default = {}
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
