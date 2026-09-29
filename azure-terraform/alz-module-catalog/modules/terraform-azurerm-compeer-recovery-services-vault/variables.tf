variable "name" {
  description = "Resource name. Changing this forces a new resource."
  type        = string
}
variable "resource_group_name" {
  description = "Resource group. Changing this forces a new resource."
  type        = string
}
variable "location" {
  description = "Azure region. Changing this forces a new resource."
  type        = string
}
variable "sku" {
  type    = string
  default = "Standard"

  validation {
    condition     = contains(["Standard", "RS0"], var.sku)
    error_message = "sku must be Standard or RS0."
  }
}
variable "storage_mode_type" {
  type    = string
  default = "GeoRedundant"

  validation {
    condition     = contains(["GeoRedundant", "LocallyRedundant", "ZoneRedundant"], var.storage_mode_type)
    error_message = "storage_mode_type must be GeoRedundant, LocallyRedundant, or ZoneRedundant."
  }
}
variable "public_network_access_enabled" {
  type    = bool
  default = null
}
variable "immutability" {
  type    = string
  default = null

  validation {
    condition     = var.immutability == null ? true : contains(["Disabled", "Unlocked", "Locked"], var.immutability)
    error_message = "immutability must be Disabled, Unlocked, or Locked."
  }
}
variable "cross_region_restore_enabled" {
  type    = bool
  default = null
}
variable "classic_vmware_replication_enabled" {
  type    = bool
  default = null
}
variable "identity" {
  type = object({
    type         = string
    identity_ids = optional(list(string), [])
  })
  default = null

  validation {
    condition     = var.identity == null ? true : contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity.type)
    error_message = "identity.type must be SystemAssigned, UserAssigned, or \"SystemAssigned, UserAssigned\"."
  }
}
variable "encryption" {
  type = object({
    key_id = string
    # azurerm_recovery_services_vault's own encryption block marks this
    # Required (not Optional) - a caller who omitted it would fail at
    # apply, so it needs a concrete default here rather than staying
    # unset. false (single encryption) matches every other secure-default
    # posture in this module without forcing every caller to type it.
    infrastructure_encryption_enabled = optional(bool, false)
    use_system_assigned_identity      = optional(bool)
    user_assigned_identity_id         = optional(string)
  })
  default = null
}
variable "monitoring" {
  type = object({
    alerts_for_all_job_failures_enabled            = optional(bool)
    alerts_for_all_failover_issues_enabled         = optional(bool)
    alerts_for_all_replication_issues_enabled      = optional(bool)
    alerts_for_critical_operation_failures_enabled = optional(bool)
    email_notifications_for_site_recovery_enabled  = optional(bool)
  })
  default = null
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
  description = "Tags applied to the resource."
  type        = map(string)
  default     = {}
}

variable "backup_policy_vm" {
  description = "VM backup policies keyed by a caller-stable tier name (tier0, standard, ...)."
  type = map(object({
    name                           = string
    policy_type                    = optional(string, "V2")
    timezone                       = optional(string, "UTC")
    instant_restore_retention_days = optional(number)
    backup = object({
      frequency     = string
      time          = string
      hour_interval = optional(number)
      hour_duration = optional(number)
      weekdays      = optional(list(string))
    })
    retention_daily   = optional(object({ count = number }))
    retention_weekly  = optional(object({ count = number, weekdays = list(string) }))
    retention_monthly = optional(object({ count = number, weekdays = optional(list(string)), weeks = optional(list(string)), days = optional(list(number)), include_last_days = optional(bool) }))
    retention_yearly  = optional(object({ count = number, months = list(string), weekdays = optional(list(string)), weeks = optional(list(string)), days = optional(list(number)), include_last_days = optional(bool) }))
  }))
  default = {}

  # Bounds below are azurerm_backup_policy_vm's own documented limits, not
  # invented ones - a value outside these fails at apply, after any sibling
  # policy in the same for_each may have already been created.
  validation {
    condition     = alltrue([for p in values(var.backup_policy_vm) : contains(["V1", "V2"], try(p.policy_type, "V2"))])
    error_message = "backup_policy_vm[*].policy_type must be V1 or V2."
  }
  validation {
    condition     = alltrue([for p in values(var.backup_policy_vm) : contains(["Hourly", "Daily", "Weekly"], p.backup.frequency)])
    error_message = "backup_policy_vm[*].backup.frequency must be Hourly, Daily, or Weekly."
  }
  validation {
    condition = alltrue([
      for p in values(var.backup_policy_vm) :
      try(p.backup.hour_interval, null) == null ? true : contains([4, 6, 8, 12], p.backup.hour_interval)
    ])
    error_message = "backup_policy_vm[*].backup.hour_interval, when set, must be 4, 6, 8, or 12."
  }
  validation {
    condition = alltrue([
      for p in values(var.backup_policy_vm) :
      try(p.backup.hour_duration, null) == null ? true : (p.backup.hour_duration >= 4 && p.backup.hour_duration <= 24)
    ])
    error_message = "backup_policy_vm[*].backup.hour_duration, when set, must be between 4 and 24."
  }
  validation {
    condition = alltrue([
      for p in values(var.backup_policy_vm) :
      try(p.retention_daily.count, null) == null ? true : (p.retention_daily.count >= 7 && p.retention_daily.count <= 9999)
    ])
    error_message = "backup_policy_vm[*].retention_daily.count, when set, must be between 7 and 9999."
  }
  validation {
    condition = alltrue([
      for p in values(var.backup_policy_vm) :
      try(p.retention_weekly.count, null) == null ? true : (p.retention_weekly.count >= 1 && p.retention_weekly.count <= 9999)
    ])
    error_message = "backup_policy_vm[*].retention_weekly.count, when set, must be between 1 and 9999."
  }
  validation {
    condition = alltrue([
      for p in values(var.backup_policy_vm) :
      try(p.retention_monthly.count, null) == null ? true : (p.retention_monthly.count >= 1 && p.retention_monthly.count <= 9999)
    ])
    error_message = "backup_policy_vm[*].retention_monthly.count, when set, must be between 1 and 9999."
  }
  validation {
    condition = alltrue([
      for p in values(var.backup_policy_vm) :
      try(p.retention_yearly.count, null) == null ? true : (p.retention_yearly.count >= 1 && p.retention_yearly.count <= 9999)
    ])
    error_message = "backup_policy_vm[*].retention_yearly.count, when set, must be between 1 and 9999."
  }
  validation {
    condition = alltrue([
      for p in values(var.backup_policy_vm) :
      try(p.instant_restore_retention_days, null) == null ? true : (
        try(p.policy_type, "V2") == "V1" ?
        (p.instant_restore_retention_days >= 1 && p.instant_restore_retention_days <= 5) :
        (p.instant_restore_retention_days >= 1 && p.instant_restore_retention_days <= 30)
      )
    ])
    error_message = "backup_policy_vm[*].instant_restore_retention_days must be 1-5 when policy_type is V1, or 1-30 when policy_type is V2."
  }
}

variable "backup_policy_file_share" {
  description = "Azure Files backup policies keyed by tier name."
  type = map(object({
    name              = string
    timezone          = optional(string, "UTC")
    backup            = object({ frequency = string, time = string })
    retention_daily   = object({ count = number })
    retention_weekly  = optional(object({ count = number, weekdays = list(string) }))
    retention_monthly = optional(object({ count = number, weekdays = list(string), weeks = list(string) }))
    retention_yearly  = optional(object({ count = number, weekdays = list(string), weeks = list(string), months = list(string) }))
  }))
  default = {}

  # Bounds are azurerm_backup_policy_file_share's own documented limits -
  # notably smaller than backup_policy_vm's, and Daily/Hourly only (no
  # Weekly), so these are NOT interchangeable with the VM validations above.
  validation {
    condition     = alltrue([for p in values(var.backup_policy_file_share) : contains(["Daily", "Hourly"], p.backup.frequency)])
    error_message = "backup_policy_file_share[*].backup.frequency must be Daily or Hourly."
  }
  validation {
    condition     = alltrue([for p in values(var.backup_policy_file_share) : p.retention_daily.count >= 1 && p.retention_daily.count <= 200])
    error_message = "backup_policy_file_share[*].retention_daily.count must be between 1 and 200."
  }
  validation {
    condition = alltrue([
      for p in values(var.backup_policy_file_share) :
      try(p.retention_weekly.count, null) == null ? true : (p.retention_weekly.count >= 1 && p.retention_weekly.count <= 200)
    ])
    error_message = "backup_policy_file_share[*].retention_weekly.count, when set, must be between 1 and 200."
  }
  validation {
    condition = alltrue([
      for p in values(var.backup_policy_file_share) :
      try(p.retention_monthly.count, null) == null ? true : (p.retention_monthly.count >= 1 && p.retention_monthly.count <= 120)
    ])
    error_message = "backup_policy_file_share[*].retention_monthly.count, when set, must be between 1 and 120."
  }
  validation {
    condition = alltrue([
      for p in values(var.backup_policy_file_share) :
      try(p.retention_yearly.count, null) == null ? true : (p.retention_yearly.count >= 1 && p.retention_yearly.count <= 10)
    ])
    error_message = "backup_policy_file_share[*].retention_yearly.count, when set, must be between 1 and 10."
  }
}
