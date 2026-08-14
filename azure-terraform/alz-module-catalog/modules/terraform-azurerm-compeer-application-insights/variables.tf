variable "name" {
  description = "Specifies the name of the Application Insights component. Changing this forces a new resource to be created."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the Application Insights component. Changing this forces a new resource to be created."
  type        = string
}

variable "location" {
  description = "Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
  type        = string
}

variable "application_type" {
  description = "Specifies the type of Application Insights to create. Valid values are ios for iOS, java for Java web, MobileCenter for App Center, Node.JS for Node.js, other for General, phone for Windows Phone, store for Windows Store and web for ASP.NET. Please note these values are case sensitive; unmatched values are treated as ASP.NET by Azure. Changing this forces a new resource to be created."
  type        = string
}

variable "daily_data_cap_in_gb" {
  description = " Specifies the Application Insights component daily data volume cap in GB."
  type        = number
  default     = null
}

variable "daily_data_cap_notifications_disabled" {
  description = "Specifies if a notification email will be send when the daily data volume cap is met."
  type        = bool
  default     = null
}

variable "retention_in_days" {
  description = "Specifies the retention period in days. Possible values are 30, 60, 90, 120, 180, 270, 365, 550 or 730. Defaults to 90."
  type        = number
  default     = 30
  validation {
    condition     = contains([30, 60, 90, 120, 180, 270, 365, 550, 730], var.retention_in_days)
    error_message = "The retention days must be one of the allowed values 30, 60, 90, 120, 180, 270, 365, 550, or 730."
  }
}

variable "sampling_percentage" {
  description = "Specifies the percentage of the data produced by the monitored application that is sampled for Application Insights telemetry."
  type        = number
  default     = null
}

variable "disable_ip_masking" {
  description = "By default the real client IP is masked as 0.0.0.0 in the logs. Use this argument to disable masking and log the real client IP."
  type        = bool
  default     = null
}

variable "workspace_id" {
  description = "Specifies the id of a log analytics workspace resource."
  type        = string
  default     = null
}

variable "local_authentication_disabled" {
  description = "Disable Non-Azure AD based Auth."
  type        = bool
  default     = null
}

variable "internet_ingestion_enabled" {
  description = "Should the Application Insights component support ingestion over the Public Internet?"
  type        = bool
  default     = false
}

variable "internet_query_enabled" {
  description = "Should the Application Insights component support querying over the Public Internet?"
  type        = bool
  default     = false
}

variable "force_customer_storage_for_profiler" {
  description = "Should the Application Insights component force users to create their own storage account for profiling?"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = {}
}