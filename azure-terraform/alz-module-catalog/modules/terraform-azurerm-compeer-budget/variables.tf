variable "scope_type" {
  type        = string
  description = "Budget scope. When null, legacy create_for_* flags are used."
  default     = null

  validation {
    condition     = var.scope_type == null || contains(["resource_group", "subscription", "management_group"], var.scope_type)
    error_message = "scope_type must be null, resource_group, subscription, or management_group."
  }
}

variable "create_for_rg" {
  type        = bool
  description = "Legacy compatibility flag for creating a resource group budget."
  default     = true
}

variable "create_for_subscription" {
  type        = bool
  description = "Legacy compatibility flag for creating a subscription budget."
  default     = false
}

variable "create_for_management_group" {
  type        = bool
  description = "Compatibility flag for creating a management group budget."
  default     = false
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name when scope_type is resource_group."
  default     = null
}

variable "resource_group_location" {
  type        = string
  description = "Legacy compatibility input. Resource group budgets use the existing resource group location."
  default     = "eastus2"
}

variable "subscription_id" {
  type        = string
  description = "Subscription resource ID or GUID when scope_type is subscription."
  default     = null
}

variable "management_group_id" {
  type        = string
  description = "Management group resource ID when scope_type is management_group."
  default     = null
}

variable "budget_name" {
  type        = string
  description = "Budget name."
  default     = null
}

variable "rg_budget_name" {
  type        = string
  description = "Legacy compatibility budget name."
  default     = null
}

variable "amount" {
  type        = number
  description = "Budget amount."
  default     = null

  validation {
    condition     = var.amount == null || var.amount > 0
    error_message = "amount must be greater than zero when provided."
  }
}

variable "rg_amount" {
  type        = number
  description = "Legacy compatibility budget amount."
  default     = null

  validation {
    condition     = var.rg_amount == null || var.rg_amount > 0
    error_message = "rg_amount must be greater than zero when provided."
  }
}

variable "time_grain" {
  type        = string
  description = "Budget time grain."
  default     = "Monthly"

  validation {
    condition     = contains(["Monthly", "Quarterly", "Annually", "BillingMonth", "BillingQuarter", "BillingAnnual"], var.time_grain)
    error_message = "time_grain must be Monthly, Quarterly, Annually, BillingMonth, BillingQuarter, or BillingAnnual."
  }
}

variable "start_date" {
  type        = string
  description = "Budget start date in RFC3339 format."
  default     = null
}

variable "budget_start_date" {
  type        = string
  description = "Legacy compatibility budget start date in RFC3339 format."
  default     = null
}

variable "end_date" {
  type        = string
  description = "Optional budget end date in RFC3339 format."
  default     = null
}

variable "notification_operator" {
  type        = string
  description = "Legacy compatibility notification operator."
  default     = "GreaterThanOrEqualTo"

  validation {
    condition     = contains(["EqualTo", "GreaterThan", "GreaterThanOrEqualTo"], var.notification_operator)
    error_message = "notification_operator must be EqualTo, GreaterThan, or GreaterThanOrEqualTo."
  }
}

variable "notification_threshold" {
  type        = number
  description = "Legacy compatibility notification threshold."
  default     = 80

  validation {
    condition     = var.notification_threshold >= 0
    error_message = "notification_threshold must be zero or greater."
  }
}

variable "notification_threshold_type" {
  type        = string
  description = "Legacy compatibility notification threshold type."
  default     = "Actual"

  validation {
    condition     = contains(["Actual", "Forecasted"], var.notification_threshold_type)
    error_message = "notification_threshold_type must be Actual or Forecasted."
  }
}

variable "notification_contact_emails" {
  type        = list(string)
  description = "Legacy compatibility notification email recipients."
  default     = []
}

variable "notification_contact_groups" {
  type        = list(string)
  description = "Legacy compatibility notification action group IDs."
  default     = []
}

variable "notification_contact_roles" {
  type        = list(string)
  description = "Legacy compatibility notification contact roles."
  default     = []
}

variable "notifications" {
  type = map(object({
    enabled        = optional(bool, true)
    operator       = optional(string, "GreaterThanOrEqualTo")
    threshold      = number
    threshold_type = optional(string, "Actual")
    contact_emails = optional(list(string), [])
    contact_groups = optional(list(string), [])
    contact_roles  = optional(list(string), [])
  }))
  description = "Named budget notifications. When empty, the legacy notification_* inputs are used."
  default     = {}

  validation {
    condition = alltrue([
      for notification in values(var.notifications) :
      contains(["EqualTo", "GreaterThan", "GreaterThanOrEqualTo"], notification.operator)
    ])
    error_message = "Each notification operator must be EqualTo, GreaterThan, or GreaterThanOrEqualTo."
  }

  validation {
    condition = alltrue([
      for notification in values(var.notifications) :
      contains(["Actual", "Forecasted"], notification.threshold_type)
    ])
    error_message = "Each notification threshold_type must be Actual or Forecasted."
  }
}
