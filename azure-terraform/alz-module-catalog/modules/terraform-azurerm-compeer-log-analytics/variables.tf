variable "log_analytics_workspace_name" {
  description = "Name of Log Analystics Workspace."
  type        = string
}

variable "location" {
  description = "The supported Azure location where the resource exists. Changing this forces a new resource to be created."
  type        = string
}

variable "resource_group_name" {
  description = "Name of resource group to deploy resources in."
  type        = string
}

variable "log_analytics_sku" {
  description = "Specified the Sku of the Log Analytics Workspace."
  type        = string
  default     = "PerGB2018"
}

variable "log_analytics_retention_in_days" {
  description = "The workspace data retetion in days. Possible values range between 30 and 730."
  type        = number
  default     = 180
}

variable "log_analytics_daily_quota_gb" {
  description = "The workspace daily quota for ingestion in GB. Defaults to -1 (unlimited) if omitted."
  type        = number
  default     = -1
}

variable "allow_resource_only_permissions" {
  type    = bool
  default = null
}

variable "cmk_for_query_forced" {
  type    = bool
  default = null
}

variable "data_collection_rule_id" {
  type    = string
  default = null
}

variable "immediate_data_purge_on_30_days_enabled" {
  type    = bool
  default = null
}

variable "internet_ingestion_enabled" {
  type    = bool
  default = null
}

variable "internet_query_enabled" {
  type    = bool
  default = null
}

variable "local_authentication_disabled" {
  type    = bool
  default = null
}

variable "reservation_capacity_in_gb_per_day" {
  type    = number
  default = null
}

variable "identity" {
  type = object({
    type         = string
    identity_ids = optional(list(string), [])
  })
  default = null
}

variable "timeouts" {
  type = object({
    create = optional(string)
    update = optional(string)
    read   = optional(string)
    delete = optional(string)
  })
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources created."
  type        = map(string)
  default     = {}
}
