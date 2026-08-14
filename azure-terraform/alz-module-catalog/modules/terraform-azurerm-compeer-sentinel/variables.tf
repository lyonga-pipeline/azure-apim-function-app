variable "enabled" {
  description = "Set true to onboard Sentinel to the Log Analytics workspace."
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID to onboard to Sentinel."
  type        = string
}

variable "approved_data_connectors" {
  description = "No-cost connector contract used to record which Sentinel data connectors must be enabled by the SOC design."
  type = map(object({
    connector_type = string
    source         = optional(string)
    enabled        = optional(bool, false)
    notes          = optional(string)
  }))
  default = {}
}
