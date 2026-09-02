variable "tenant_id" {
  description = "Microsoft Entra tenant ID used by the shared-services workspace."
  type        = string
}

variable "subscription_id" {
  description = "Shared-services subscription ID."
  type        = string
}

variable "location" {
  description = "Azure region for shared-services resources."
  type        = string
  default     = "centralus"
}

variable "environment" {
  description = "Environment label used in names and tags."
  type        = string
  default     = "prod"
}

variable "platform_tags" {
  description = "Enterprise tag contract for shared-services resources."
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
  description = "Workspace that publishes hub and Private DNS outputs."
  type        = string
  default     = "platform-connectivity"
}

variable "log_analytics_workspace_id" {
  description = "Explicit Log Analytics workspace ID. Overrides management workspace output when set."
  type        = string
  default     = null
}

variable "private_dns_zone_link_keys" {
  description = "Connectivity private DNS zone keys to link into the shared-services VNet when private_dns_zone_links is not explicitly provided."
  type        = list(string)
  default     = ["key_vault", "storage_blob", "storage_queue", "storage_file"]
}

variable "shared_services" {
  description = "Shared-services workspace configuration."
  type        = any
  default = {
    enabled = false
  }
}

variable "workload_domain" {
  description = "Workload-tier domain token for Appendix F naming (RG, VNet)."
  type        = string
  default     = "shared-services"
}
