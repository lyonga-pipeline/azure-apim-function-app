variable "tenant_id" {
  description = "Entra tenant ID. Provide via the shared HCP variable set as a Terraform-category variable named `tenant_id`. Do NOT set it in a .tfvars file."
  type        = string
}

variable "subscription_id" {
  description = "The MANAGEMENT subscription ID (where the central Log Analytics workspace lives). Set it as a workspace-level Terraform-category variable in HCP. Do NOT set it in a .tfvars file."
  type        = string
}

variable "use_tfe_outputs" {
  description = "Read the Log Analytics workspace ID and Sentinel onboarding state from the management workspace. False requires log_analytics_workspace_id."
  type        = bool
  default     = true
}

variable "tfe_organization" {
  description = "HCP Terraform organization that contains the management workspace."
  type        = string
  default     = null
}

variable "management_workspace_name" {
  description = "Workspace that publishes log_analytics_workspace_id and sentinel_onboarding_id."
  type        = string
  default     = "platform-management"
}

variable "log_analytics_workspace_id" {
  description = "Explicit Log Analytics workspace ID. Overrides the management workspace output; use with use_tfe_outputs = false for isolated testing."
  type        = string
  default     = null
}

variable "taxii_passwords" {
  description = "TAXII feed passwords keyed like sentinel.data_connectors.threat_intelligence_taxii. Set as a sensitive HCP variable; never in a .tfvars file."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "sentinel" {
  description = "Sentinel content configuration. Keep enabled = false until the SOC has approved the content and platform-management has onboarded Sentinel. See patterns/terraform-azurerm-compeer-sentinel-content for every field."
  type        = any
  default     = { enabled = false }
}
