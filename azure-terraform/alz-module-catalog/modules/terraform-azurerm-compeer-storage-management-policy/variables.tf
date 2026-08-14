variable "storage_account_id" { type = string }
variable "rules" {
  type = map(object({
    enabled = optional(bool, true)
    filters = object({
      blob_types   = set(string)
      prefix_match = optional(set(string), [])
      match_blob_index_tag = optional(list(object({
        name      = string
        operation = optional(string)
        value     = string
      })), [])
    })
    actions = object({
      base_blob = optional(object({
        auto_tier_to_hot_from_cool_enabled                             = optional(bool)
        delete_after_days_since_creation_greater_than                  = optional(number)
        delete_after_days_since_last_access_time_greater_than          = optional(number)
        delete_after_days_since_modification_greater_than              = optional(number)
        tier_to_archive_after_days_since_creation_greater_than         = optional(number)
        tier_to_archive_after_days_since_last_access_time_greater_than = optional(number)
        tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
        tier_to_archive_after_days_since_modification_greater_than     = optional(number)
        tier_to_cold_after_days_since_creation_greater_than            = optional(number)
        tier_to_cold_after_days_since_last_access_time_greater_than    = optional(number)
        tier_to_cold_after_days_since_modification_greater_than        = optional(number)
        tier_to_cool_after_days_since_creation_greater_than            = optional(number)
        tier_to_cool_after_days_since_last_access_time_greater_than    = optional(number)
        tier_to_cool_after_days_since_modification_greater_than        = optional(number)
      }))
      snapshot = optional(object({
        change_tier_to_archive_after_days_since_creation               = optional(number)
        change_tier_to_cool_after_days_since_creation                  = optional(number)
        delete_after_days_since_creation_greater_than                  = optional(number)
        tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
        tier_to_cold_after_days_since_creation_greater_than            = optional(number)
      }))
      version = optional(object({
        change_tier_to_archive_after_days_since_creation               = optional(number)
        change_tier_to_cool_after_days_since_creation                  = optional(number)
        delete_after_days_since_creation                               = optional(number)
        tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
        tier_to_cold_after_days_since_creation_greater_than            = optional(number)
      }))
    })
  }))
  default = {}
}
variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}
