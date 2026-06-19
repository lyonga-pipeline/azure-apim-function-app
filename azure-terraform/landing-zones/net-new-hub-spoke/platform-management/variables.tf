variable "subscription_id" {
  type        = string
  description = "Platform management subscription id."
}

variable "location" {
  type        = string
  description = "Azure region for management resources."
}

variable "environment" {
  type        = string
  description = "Environment key, such as np or prod."
}

variable "platform_tags" {
  type = object({
    application         = string
    business_owner      = string
    source_repo         = string
    terraform_workspace = string
    recovery_tier       = string
    cost_center         = string
    data_classification = string
    compliance_boundary = string
    additional_tags     = optional(map(string), {})
  })
}

variable "resource_group" {
  type = object({
    name = string
  })
}

variable "log_analytics" {
  type = object({
    name              = string
    retention_in_days = optional(number, 90)
    daily_quota_gb    = optional(number)
  })
}

variable "action_group" {
  type = object({
    name       = string
    short_name = string
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
  })
}

