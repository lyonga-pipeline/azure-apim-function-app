variable "subscription_id" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "action_groups" {
  description = "Azure Monitor action groups."
  type = map(object({
    name       = string
    short_name = string
    enabled    = optional(bool, true)
    receivers = optional(object({
      email = optional(map(object({
        email_address           = string
        use_common_alert_schema = optional(bool, true)
      })), {})
      webhook = optional(map(object({
        service_uri             = string
        use_common_alert_schema = optional(bool, true)
      })), {})
      sms = optional(map(object({
        country_code = string
        phone_number = string
      })), {})
      voice = optional(map(object({
        country_code = string
        phone_number = string
      })), {})
      arm_role = optional(map(object({
        role_id                 = string
        use_common_alert_schema = optional(bool, true)
      })), {})
    }), {})
  }))
  default = {}
}

variable "metric_alerts" {
  description = "Baseline Azure Monitor metric alerts."
  type = map(object({
    name                     = string
    scopes                   = set(string)
    description              = optional(string)
    enabled                  = optional(bool, true)
    auto_mitigate            = optional(bool, true)
    severity                 = optional(number, 3)
    frequency                = optional(string, "PT5M")
    window_size              = optional(string, "PT5M")
    target_resource_type     = optional(string)
    target_resource_location = optional(string)
    criteria = optional(map(object({
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
    })), {})
    dynamic_criteria = optional(object({
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
    }))
    application_insights_web_test_location_availability_criteria = optional(object({
      component_id          = string
      web_test_id           = string
      failed_location_count = number
    }))
    action_group_keys = optional(list(string), [])
    actions = optional(map(object({
      action_group_id    = string
      webhook_properties = optional(map(string), {})
    })), {})
  }))
  default = {}
}

variable "operational_contracts" {
  description = "Phase 2 monitoring, SecOps, and platform operations controls."
  type = map(object({
    phase                = optional(string, "Phase 2")
    owner                = optional(string)
    enabled              = optional(bool, false)
    cost_disabled        = optional(bool, true)
    implementation_state = optional(string, "contract-only")
    required_controls    = optional(list(string), [])
    evidence_locations   = optional(list(string), [])
    notes                = optional(string)
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
