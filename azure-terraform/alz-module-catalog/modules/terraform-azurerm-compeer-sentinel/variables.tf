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

variable "data_connectors" {
  description = "Terraform-owned Sentinel data connectors to enable."
  type = object({
    threat_intelligence = optional(bool, false)
    defender_atp        = optional(bool, false)
    entra_id            = optional(bool, false)
    defender_for_cloud  = optional(bool, false)
  })
  default = {}
}

variable "include_default_rules" {
  description = "Include the baseline scheduled analytics rules (Palo Alto CEF forwarding-health + critical-threat)."
  type        = bool
  default     = true
}

variable "scheduled_alert_rules" {
  description = "Additional scheduled analytics rules keyed by rule name."
  type = map(object({
    display_name      = string
    severity          = string
    query             = string
    query_frequency   = optional(string, "PT1H")
    query_period      = optional(string, "PT1H")
    trigger_operator  = optional(string, "GreaterThan")
    trigger_threshold = optional(number, 0)
    tactics           = optional(list(string))
    enabled           = optional(bool, true)
    create_incident   = optional(bool, true)
    grouping_enabled  = optional(bool, true)
  }))
  default = {}
}
