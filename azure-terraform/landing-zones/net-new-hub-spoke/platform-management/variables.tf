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

variable "resource_provider_registrations" {
  type = map(object({
    features = optional(map(object({
      registered = bool
    })), {})
  }))
  description = "Azure resource providers that must be explicitly registered for the platform subscription."
  default     = {}
}

variable "additional_lock_scopes" {
  type        = map(string)
  description = "Additional named scopes that can be referenced by management_locks or role_assignments."
  default     = {}
}

variable "role_assignments" {
  type = map(object({
    scope_key                              = optional(string)
    scope                                  = optional(string)
    principal_id                           = string
    role_definition_name                   = optional(string)
    role_definition_id                     = optional(string)
    principal_type                         = optional(string)
    description                            = optional(string)
    condition                              = optional(string)
    condition_version                      = optional(string)
    skip_service_principal_aad_check       = optional(bool)
    delegated_managed_identity_resource_id = optional(string)
  }))
  description = "Subscription and platform-resource RBAC assignments."
  default     = {}

  validation {
    condition = alltrue([
      for assignment in values(var.role_assignments) :
      (
        (try(assignment.scope, null) != null || try(assignment.scope_key, null) != null) &&
        !(try(assignment.scope, null) != null && try(assignment.scope_key, null) != null)
      )
    ])
    error_message = "Each role assignment must set exactly one of scope or scope_key."
  }
}

variable "subscription_activity_log_diagnostics" {
  type = object({
    name                           = string
    storage_account_id             = optional(string)
    eventhub_authorization_rule_id = optional(string)
    eventhub_name                  = optional(string)
    logs = map(object({
      category = string
    }))
  })
  description = "Subscription activity-log export to the platform Log Analytics workspace and optional archive destinations."
  default     = null
}

variable "entra_diagnostic_settings" {
  type = object({
    name                           = string
    storage_account_id             = optional(string)
    eventhub_authorization_rule_id = optional(string)
    eventhub_name                  = optional(string)
    logs = map(object({
      category = string
    }))
  })
  description = "Microsoft Entra diagnostic export. Requires tenant-level permissions."
  default     = null
}

variable "subscription_budgets" {
  type = map(object({
    amount     = number
    time_grain = string
    time_period = object({
      start_date = string
      end_date   = optional(string)
    })
    notifications = map(object({
      enabled        = optional(bool, true)
      threshold      = number
      operator       = string
      threshold_type = optional(string, "Actual")
      contact_emails = optional(list(string))
      contact_groups = optional(list(string))
      contact_roles  = optional(list(string))
    }))
  }))
  description = "Subscription-level FinOps budgets."
  default     = {}
}

variable "management_locks" {
  type = map(object({
    name       = string
    scope_key  = optional(string)
    scope      = optional(string)
    lock_level = string
    notes      = optional(string)
  }))
  description = "Management locks for critical platform resources."
  default     = {}

  validation {
    condition = alltrue([
      for item in values(var.management_locks) :
      (
        (try(item.scope, null) != null || try(item.scope_key, null) != null) &&
        !(try(item.scope, null) != null && try(item.scope_key, null) != null)
      )
    ])
    error_message = "Each management lock must set exactly one of scope or scope_key."
  }
}

variable "defender_plans" {
  type = map(object({
    resource_type = string
    tier          = string
    subplan       = optional(string)
    extensions = optional(map(object({
      name                            = string
      additional_extension_properties = optional(map(string))
    })), {})
  }))
  description = "Microsoft Defender for Cloud subscription pricing plans."
  default     = {}
}

variable "security_contact" {
  type = object({
    name                = optional(string, "default")
    email               = string
    phone               = optional(string)
    alert_notifications = optional(bool, true)
    alerts_to_admins    = optional(bool, true)
  })
  description = "Microsoft Defender for Cloud security contact."
  default     = null
}

variable "security_center_settings" {
  type = map(object({
    enabled = bool
  }))
  description = "Microsoft Defender for Cloud settings such as MCAS and WDATP."
  default     = {}
}
