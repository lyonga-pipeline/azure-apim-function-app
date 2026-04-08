variable "environment" {
  type        = string
  description = "Environment tag."
}

variable "application" {
  type        = string
  description = "Application code."
  default     = "management"
}

variable "created_by" {
  type        = string
  description = "Provisioning source tag."
  default     = "terraform"
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "subscription_id" {
  type        = string
  description = "Subscription id for activity log export."
}

variable "subscription_catalog_entry_key" {
  type        = string
  description = "Entry key in the subscriptions catalog for this stack."
  default     = "management"
}

variable "use_subscriptions_state" {
  type        = bool
  description = "Validate the stack subscription against the central subscriptions state."
  default     = true
}

variable "subscriptions_state_rg" {
  type        = string
  description = "Resource group hosting the subscriptions stack state."
  default     = "rg-tfstate-dev"
}

variable "subscriptions_state_sa" {
  type        = string
  description = "Storage account hosting the subscriptions stack state."
  default     = "demotest822e"
}

variable "subscriptions_state_container" {
  type        = string
  description = "Container hosting the subscriptions stack state."
  default     = "deploy-container"
}

variable "subscriptions_state_key" {
  type        = string
  description = "State blob key for the subscriptions stack."
  default     = "global/subscriptions.tfstate"
}

variable "subscriptions_state_subscription_id" {
  type        = string
  description = "Subscription containing the subscriptions stack remote state."
  default     = null
}

variable "resource_group_name" {
  type        = string
  description = "Management resource group."
}

variable "workspace_name" {
  type        = string
  description = "Log Analytics workspace name."
}

variable "workspace_retention_in_days" {
  type        = number
  description = "Workspace retention."
  default     = 90
}

variable "diagnostics_storage_account_name" {
  type        = string
  description = "Diagnostics archive storage account."
}

variable "action_group_name" {
  type        = string
  description = "Action group name."
}

variable "action_group_short_name" {
  type        = string
  description = "Action group short name."
  default     = "ops"
}

variable "action_group_email_receivers" {
  type        = map(string)
  description = "Action group email receivers."
  default     = {}
}

variable "recovery_services_vault_name" {
  type        = string
  description = "Recovery Services Vault name."
}

variable "enable_diagnostics_storage_insights" {
  type        = bool
  description = "Enable Log Analytics Storage Insights for the diagnostics archive. Leave disabled when using keyless storage access."
  default     = false
}

variable "enable_defender" {
  type        = bool
  description = "Enable Microsoft Defender for Cloud Standard tier plans for AppServices, KeyVaults, SqlServers, SqlServerVirtualMachines, StorageAccounts, Containers, and Arm. Set false for personal testing to avoid Defender costs. Required for finserv production deployments."
  default     = false
}

variable "business_owner" {
  type        = string
  description = "Business owner tag."
  default     = "operations"
}

variable "source_repo" {
  type        = string
  description = "Source repository tag."
  default     = "azure-apim-function-app"
}

variable "terraform_workspace" {
  type        = string
  description = "Terraform workspace or stack name."
  default     = "platform-management"
}

variable "recovery_tier" {
  type        = string
  description = "Recovery method tag."
  default     = "rubrik"
}

variable "cost_center" {
  type        = string
  description = "Cost center tag."
  default     = "shared-ops"
}

variable "compliance_boundary" {
  type        = string
  description = "Compliance boundary tag."
  default     = "finserv"
}

variable "creation_date_utc" {
  type        = string
  description = "Optional immutable creation timestamp tag."
  default     = null
}

variable "last_modified_utc" {
  type        = string
  description = "Optional last modified timestamp tag."
  default     = null
}

variable "additional_tags" {
  type        = map(string)
  description = "Additional tags."
  default     = {}
}
