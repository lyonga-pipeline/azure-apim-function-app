variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "scopes" {
  type = set(string)

  validation {
    condition     = length(var.scopes) > 0
    error_message = "At least one scope is required."
  }
}
variable "description" {
  type    = string
  default = null
}
variable "enabled" {
  type    = bool
  default = true
}
variable "auto_mitigate" {
  type    = bool
  default = true
}
variable "severity" {
  type    = number
  default = 3

  validation {
    condition     = var.severity >= 0 && var.severity <= 4
    error_message = "severity must be between 0 and 4."
  }
}
variable "frequency" {
  type    = string
  default = "PT5M"
}
variable "window_size" {
  type    = string
  default = "PT5M"
}
variable "target_resource_type" {
  type    = string
  default = null
}
variable "target_resource_location" {
  type    = string
  default = null
}
variable "criteria" {
  type = map(object({
    metric_namespace       = string
    metric_name            = string
    aggregation            = string
    operator               = string
    threshold              = number
    skip_metric_validation = optional(bool)
    dimensions = optional(map(object({
      name     = string
      operator = string
      values   = list(string)
    })), {})
  }))
  default = {}
}
variable "dynamic_criteria" {
  type = object({
    metric_namespace         = string
    metric_name              = string
    aggregation              = string
    operator                 = string
    alert_sensitivity        = string
    evaluation_total_count   = optional(number)
    evaluation_failure_count = optional(number)
    ignore_data_before       = optional(string)
    skip_metric_validation   = optional(bool)
    dimensions = optional(map(object({
      name     = string
      operator = string
      values   = list(string)
    })), {})
  })
  default = null
}
variable "application_insights_web_test_location_availability_criteria" {
  type = object({
    component_id          = string
    web_test_id           = string
    failed_location_count = number
  })
  default = null
}
variable "actions" {
  type = map(object({
    action_group_id    = string
    webhook_properties = optional(map(string), {})
  }))
  default = {}
}
variable "tags" {
  type    = map(string)
  default = {}
}
