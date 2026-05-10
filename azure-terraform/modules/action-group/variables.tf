variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "short_name" { type = string }
variable "enabled" {
  type    = bool
  default = true
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
  })
  default = {}
}
variable "tags" {
  type    = map(string)
  default = {}
}
