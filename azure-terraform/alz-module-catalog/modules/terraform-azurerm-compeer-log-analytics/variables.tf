variable "log_analytics_workspace_name" {
  description = "Name of Log Analystics Workspace."
  type        = string
}

variable "create_resource_group" {
  description = "Whether to create a resource group?"
  type        = bool
}

variable "location" {
  description = "The supported Azure location where the resource exists. Changing this forces a new resource to be created."
  type        = string
}

variable "resource_group_name" {
  description = "Name of resource group to deploy resources in."
  type        = string
}

variable "resource_group_id" {
  description = "Id of the resource group to deploy in"
  type        = string
  default     = null
}

variable "log_analytics_role_definition_name" {
  description = "Name of role definition for role assignment."
  type        = string
  default     = null
}

variable "log_analytics_sku" {
  description = "Specified the Sku of the Log Analytics Workspace."
  type        = string
}

variable "log_analytics_retention_in_days" {
  description = "The workspace data retetion in days. Possible values range between 30 and 730."
  type        = number
  default     = 180
}

variable "log_analytics_daily_quota_gb" {
  description = "The workspace daily quota for ingestion in GB. Defaults to -1 (unlimited) if omitted."
  type        = number
  default     = 10
}

variable "log_analytics_security_center_subscription" {
  description = "List of subscriptions this log analytics should collect data for. Does not work on free subscription."
  type        = list(string)
  default     = []
}

variable "log_analytics_contributors" {
  description = "A list of users / apps that should have Log Analytics Contributer access. Required to use log analytics as log source."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources created."
  type        = map(string)
  default     = {}
}