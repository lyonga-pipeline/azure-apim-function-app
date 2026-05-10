variable "name" { type = string }
variable "scope" { type = string }
variable "included_event_types" {
  type    = list(string)
  default = []
}
variable "event_delivery_schema" {
  type    = string
  default = "EventGridSchema"
}
variable "labels" {
  type    = list(string)
  default = []
}
variable "expiration_time_utc" {
  type    = string
  default = null
}
variable "advanced_filtering_on_arrays_enabled" {
  type    = bool
  default = false
}
variable "subject_filter" {
  type = object({
    subject_begins_with = optional(string)
    subject_ends_with   = optional(string)
    case_sensitive      = optional(bool, false)
  })
  default = {}
}
variable "advanced_filter" {
  type = object({
    bool_equals = optional(list(object({
      key   = string
      value = bool
    })), [])
    is_not_null = optional(list(object({
      key = string
    })), [])
    is_null_or_undefined = optional(list(object({
      key = string
    })), [])
    number_greater_than = optional(list(object({
      key   = string
      value = number
    })), [])
    number_greater_than_or_equals = optional(list(object({
      key   = string
      value = number
    })), [])
    number_in = optional(list(object({
      key    = string
      values = list(number)
    })), [])
    number_in_range = optional(list(object({
      key    = string
      values = list(list(number))
    })), [])
    number_less_than = optional(list(object({
      key   = string
      value = number
    })), [])
    number_less_than_or_equals = optional(list(object({
      key   = string
      value = number
    })), [])
    number_not_in = optional(list(object({
      key    = string
      values = list(number)
    })), [])
    number_not_in_range = optional(list(object({
      key    = string
      values = list(list(number))
    })), [])
    string_begins_with = optional(list(object({
      key    = string
      values = list(string)
    })), [])
    string_contains = optional(list(object({
      key    = string
      values = list(string)
    })), [])
    string_ends_with = optional(list(object({
      key    = string
      values = list(string)
    })), [])
    string_in = optional(list(object({
      key    = string
      values = list(string)
    })), [])
    string_not_begins_with = optional(list(object({
      key    = string
      values = list(string)
    })), [])
    string_not_contains = optional(list(object({
      key    = string
      values = list(string)
    })), [])
    string_not_ends_with = optional(list(object({
      key    = string
      values = list(string)
    })), [])
    string_not_in = optional(list(object({
      key    = string
      values = list(string)
    })), [])
  })
  default = null
}
variable "webhook_endpoint" {
  type = object({
    active_directory_app_id_or_uri    = optional(string)
    active_directory_tenant_id        = optional(string)
    url                               = string
    max_events_per_batch              = optional(number)
    preferred_batch_size_in_kilobytes = optional(number)
  })
  default = null
}
variable "azure_function_endpoint" {
  type = object({
    function_id                       = string
    max_events_per_batch              = optional(number)
    preferred_batch_size_in_kilobytes = optional(number)
  })
  default = null
}
variable "storage_queue_endpoint" {
  type = object({
    storage_account_id                    = string
    queue_name                            = string
    queue_message_time_to_live_in_seconds = optional(number)
  })
  default = null
}
variable "eventhub_endpoint_id" {
  type    = string
  default = null
}
variable "hybrid_connection_endpoint_id" {
  type    = string
  default = null
}
variable "service_bus_queue_endpoint_id" {
  type    = string
  default = null
}
variable "service_bus_topic_endpoint_id" {
  type    = string
  default = null
}
variable "dead_letter_destination" {
  type = object({
    storage_account_id          = string
    storage_blob_container_name = string
  })
  default = null
}
variable "retry_policy" {
  type = object({
    event_time_to_live    = number
    max_delivery_attempts = number
  })
  default = null
}
variable "delivery_identity" {
  type = object({
    type                   = string
    user_assigned_identity = optional(string)
  })
  default = null
}
variable "dead_letter_identity" {
  type = object({
    type                   = string
    user_assigned_identity = optional(string)
  })
  default = null
}
variable "delivery_properties" {
  type = list(object({
    header_name  = string
    type         = string
    secret       = optional(bool)
    source_field = optional(string)
    value        = optional(string)
  }))
  default = []
}
