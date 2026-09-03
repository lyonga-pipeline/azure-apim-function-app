variable "tenant_id" {
  description = "Microsoft Entra tenant ID used by the directory-services workspace."
  type        = string
}

variable "subscription_id" {
  description = "Directory-services subscription ID."
  type        = string
}

variable "location" {
  description = "Azure region for directory-services resources."
  type        = string
  default     = "centralus"
}

variable "environment" {
  description = "Environment label used in names and tags."
  type        = string
  default     = "prod"
}

variable "platform_tags" {
  description = "Enterprise tag contract for directory-services resources."
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
  description = "Workspace that publishes hub subnet outputs."
  type        = string
  default     = "platform-connectivity"
}

variable "log_analytics_workspace_id" {
  description = "Explicit Log Analytics workspace ID. Overrides management workspace output when set."
  type        = string
  default     = null
}

variable "directory_services" {
  description = "Directory-services workspace configuration."
  type        = any
  default = {
    enabled = false
  }
}

variable "admin_passwords" {
  description = "Sensitive local administrator passwords keyed by domain controller key."
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "domain_join_passwords" {
  description = "Sensitive domain-join passwords keyed by domain controller key or configured password key."
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "ad_ds_promotion_passwords" {
  description = "Sensitive AD DS promotion passwords keyed by domain controller key or configured promotion password keys."
  type        = map(string)
  sensitive   = true
  default     = {}
}
