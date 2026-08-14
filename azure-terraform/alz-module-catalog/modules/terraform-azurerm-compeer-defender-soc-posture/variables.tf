variable "enabled" {
  description = "Master switch. Defaults false so no paid Defender or SOC resources are deployed by accident."
  type        = bool
  default     = false
}

variable "defender_plans" {
  description = "Defender for Cloud plans keyed by logical name. Only created when enabled is true."
  type = map(object({
    resource_type = string
    tier          = optional(string, "Standard")
    subplan       = optional(string)
    extensions = optional(map(object({
      name                            = string
      additional_extension_properties = optional(map(string))
    })), {})
  }))
  default = {}
}

variable "security_contact" {
  description = "Subscription security contact. Only created when enabled is true."
  type = object({
    name                = optional(string, "default")
    email               = string
    phone               = optional(string)
    alert_notifications = optional(bool, true)
    alerts_to_admins    = optional(bool, true)
  })
  default = null
}

variable "security_center_settings" {
  description = "Security Center settings keyed by setting name. Only created when enabled is true."
  type = map(object({
    enabled = bool
  }))
  default = {}
}

variable "posture_contract" {
  description = "No-cost target-state record used before SOC controls are activated."
  type = object({
    defender_standard_enabled     = optional(bool, false)
    sentinel_enabled              = optional(bool, false)
    data_collection_rules_enabled = optional(bool, false)
    security_contact_enabled      = optional(bool, false)
    notes                         = optional(string)
  })
  default = {}
}
