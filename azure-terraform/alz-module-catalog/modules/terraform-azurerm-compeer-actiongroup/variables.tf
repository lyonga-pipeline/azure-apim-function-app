variable "name" {
  description = "Name of the action group. Changing this forces a new resource."
  type        = string
}
variable "resource_group_name" {
  description = "Resource group the action group is created in. Changing this forces a new resource."
  type        = string
}
variable "short_name" {
  description = "Short name used in SMS/email subjects. 1-12 characters."
  type        = string

  validation {
    condition     = length(var.short_name) >= 1 && length(var.short_name) <= 12
    error_message = "short_name must be 1-12 characters."
  }
}
variable "enabled" {
  description = "Whether the action group is enabled."
  type        = bool
  default     = true
}
variable "receivers" {
  type = object({
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
    automation_runbook = optional(map(object({
      automation_account_id   = string
      runbook_name            = string
      webhook_resource_id     = string
      is_global_runbook       = bool
      service_uri             = string
      use_common_alert_schema = optional(bool, true)
    })), {})
    azure_app_push = optional(map(object({
      email_address = string
    })), {})
    azure_function = optional(map(object({
      function_app_resource_id = string
      function_name            = string
      http_trigger_url         = string
      use_common_alert_schema  = optional(bool, true)
    })), {})
    event_hub = optional(map(object({
      event_hub_name          = string
      event_hub_namespace     = string
      subscription_id         = string
      tenant_id               = optional(string)
      use_common_alert_schema = optional(bool, true)
    })), {})
    itsm = optional(map(object({
      workspace_id         = string
      connection_id        = string
      ticket_configuration = string
      region               = string
    })), {})
    logic_app = optional(map(object({
      resource_id             = string
      callback_url            = string
      use_common_alert_schema = optional(bool, true)
    })), {})
  })
  default = {}
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
  type    = map(string)
  default = {}
}
