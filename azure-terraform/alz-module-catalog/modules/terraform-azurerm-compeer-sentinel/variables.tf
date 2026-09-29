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

  # Enums are azurerm_sentinel_alert_rule_scheduled's own documented values -
  # a bad one only fails at apply, potentially after sibling rules in the
  # same for_each already succeeded.
  validation {
    condition     = alltrue([for r in values(var.scheduled_alert_rules) : contains(["High", "Medium", "Low", "Informational"], r.severity)])
    error_message = "scheduled_alert_rules[*].severity must be High, Medium, Low, or Informational."
  }
  validation {
    condition     = alltrue([for r in values(var.scheduled_alert_rules) : contains(["Equal", "GreaterThan", "LessThan", "NotEqual"], try(r.trigger_operator, "GreaterThan"))])
    error_message = "scheduled_alert_rules[*].trigger_operator must be Equal, GreaterThan, LessThan, or NotEqual."
  }
  validation {
    # Format only - Azure's own real-world constraint that query_period must
    # be >= query_frequency requires comparing two arbitrary ISO-8601
    # durations, which isn't reliably expressible in HCL; that comparison is
    # left to apply-time. This just catches a malformed duration string
    # (e.g. "1h" instead of "PT1H") before it gets that far.
    condition = alltrue([
      for r in values(var.scheduled_alert_rules) :
      can(regex("^P(?:[0-9]+Y)?(?:[0-9]+M)?(?:[0-9]+D)?(?:T(?:[0-9]+H)?(?:[0-9]+M)?(?:[0-9]+(?:\\.[0-9]+)?S)?)?$", try(r.query_frequency, "PT1H"))) &&
      can(regex("^P(?:[0-9]+Y)?(?:[0-9]+M)?(?:[0-9]+D)?(?:T(?:[0-9]+H)?(?:[0-9]+M)?(?:[0-9]+(?:\\.[0-9]+)?S)?)?$", try(r.query_period, "PT1H")))
    ])
    error_message = "scheduled_alert_rules[*].query_frequency and query_period must be valid ISO-8601 durations (e.g. PT1H, P1D)."
  }
}
