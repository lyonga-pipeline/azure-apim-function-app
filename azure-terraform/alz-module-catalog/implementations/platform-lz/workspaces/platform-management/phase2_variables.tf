# =============================================================================
# PHASE 2 CHANGES - additive, opt-in; preserve existing resource/state ownership.
# Copy this file together with the PHASE 2 section in main.tf and the example.
# =============================================================================
variable "phase2_log_alerts" {
  type = map(object({
    name                  = string
    query                 = string
    description           = string
    severity              = optional(number, 2)
    evaluation_frequency  = optional(string, "PT5M")
    window_duration       = optional(string, "PT30M")
    aggregation           = optional(string, "Count")
    metric_measure_column = optional(string)
    operator              = optional(string, "GreaterThan")
    threshold             = optional(number, 0)
    enabled               = optional(bool, true)
    dimensions = optional(map(object({
      name     = string
      operator = optional(string, "Include")
      values   = list(string)
    })), {})
  }))
  default = {}
  validation {
    condition     = alltrue([for alert in values(var.phase2_log_alerts) : alert.severity >= 0 && alert.severity <= 4 && length(trimspace(alert.query)) > 0])
    error_message = "Log alerts require a non-empty reviewed KQL query and severity 0-4."
  }
}

variable "phase2_metric_alerts" {
  type = map(object({
    name                     = string
    scopes                   = set(string)
    metric_namespace         = string
    metric_name              = string
    aggregation              = string
    operator                 = string
    threshold                = number
    target_resource_type     = optional(string)
    target_resource_location = optional(string)
    severity                 = optional(number, 2)
    frequency                = optional(string, "PT5M")
    window_size              = optional(string, "PT15M")
    dimensions = optional(map(object({
      name     = string
      operator = optional(string, "Include")
      values   = list(string)
    })), {})
  }))
  default = {}
  validation {
    condition     = alltrue([for alert in values(var.phase2_metric_alerts) : length(alert.scopes) > 0 && alert.severity >= 0 && alert.severity <= 4 && (length(alert.scopes) == 1 || (alert.target_resource_type != null && alert.target_resource_location != null))])
    error_message = "Metric alerts require resource scopes and severity 0-4; multiple scopes also need the target resource type and region."
  }
}

variable "phase2_workbooks" {
  type = map(object({
    name         = string
    display_name = string
    data_json    = string
  }))
  default = {}
  validation {
    condition     = alltrue([for workbook in values(var.phase2_workbooks) : can(jsondecode(workbook.data_json)) && can(regex("^[0-9a-fA-F-]{36}$", workbook.name))])
    error_message = "Workbooks require a stable UUID name and valid workbook JSON."
  }
}

variable "phase2_action_group_ids" {
  description = "Additional existing action groups. The primary management action group is reused automatically."
  type        = set(string)
  default     = []
}
