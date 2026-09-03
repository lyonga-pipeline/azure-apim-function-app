variable "tenant_id" {
  description = "Microsoft Entra tenant ID used by the Cloudflare connector workspace."
  type        = string
}

variable "subscription_id" {
  description = "Connectivity subscription ID containing connector VM resources."
  type        = string
}

variable "location" {
  description = "Azure region for connector VMs."
  type        = string
  default     = "centralus"
}

variable "environment" {
  description = "Environment label used in names and tags."
  type        = string
  default     = "prod"
}

variable "platform_tags" {
  description = "Enterprise tag contract for Cloudflare connector resources."
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

variable "cloudflare_connectors" {
  description = "Cloudflare connector VM workspace configuration."
  type        = any
  default = {
    enabled = false
  }
}

variable "admin_passwords" {
  description = "Sensitive local administrator passwords keyed by connector key."
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "custom_data_by_key" {
  description = "Sensitive base64-encoded cloud-init custom data keyed by connector key."
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "extension_protected_settings" {
  description = "Sensitive JSON protected settings keyed by connector:extension key or configured protected_settings_key."
  type        = map(string)
  sensitive   = true
  default     = {}
}
