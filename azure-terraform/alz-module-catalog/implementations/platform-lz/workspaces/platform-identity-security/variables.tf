variable "tenant_id" {
  description = "Microsoft Entra tenant ID used by the identity/security workspace."
  type        = string
}

variable "subscription_id" {
  description = "Identity/security subscription ID."
  type        = string
}

variable "location" {
  description = "Azure region for identity/security resources."
  type        = string
  default     = "centralus"
}

variable "environment" {
  description = "Environment label used in names and tags."
  type        = string
  default     = "prod"
}

variable "platform_tags" {
  description = "Enterprise tag contract for identity/security resources."
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
  description = "Read approved outputs from management and connectivity workspaces."
  type        = bool
  default     = true
}

variable "tfe_organization" {
  description = "HCP Terraform organization that contains the producer workspaces."
  type        = string
  default     = null
}

variable "management_workspace_name" {
  description = "Workspace that publishes Log Analytics outputs."
  type        = string
  default     = "platform-management"
}

variable "connectivity_workspace_name" {
  description = "Workspace that publishes private endpoint subnet and private DNS zone outputs."
  type        = string
  default     = "platform-connectivity"
}

variable "log_analytics_workspace_id" {
  description = "Explicit Log Analytics workspace ID. Overrides management workspace output when set."
  type        = string
  default     = null
}

variable "identity" {
  description = "Platform identity/security workspace configuration."
  type        = any
  default = {
    enabled = false
  }
}
