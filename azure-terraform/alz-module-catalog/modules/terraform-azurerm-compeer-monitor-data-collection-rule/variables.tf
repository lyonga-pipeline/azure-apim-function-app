variable "name" {
  type        = string
  description = "Data Collection Rule name."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "description" {
  type        = string
  description = "Data Collection Rule description."
  default     = null
}

variable "kind" {
  type        = string
  description = "Data Collection Rule kind."
  default     = null
}

variable "data_collection_endpoint_id" {
  type        = string
  description = "Optional Data Collection Endpoint ID."
  default     = null
}

variable "destinations" {
  type = object({
    log_analytics = optional(map(object({
      name                  = string
      workspace_resource_id = string
    })), {})
    azure_monitor_metrics = optional(map(object({
      name = string
    })), {})
    event_hub = optional(map(object({
      name         = string
      event_hub_id = string
    })), {})
    event_hub_direct = optional(map(object({
      name         = string
      event_hub_id = string
    })), {})
    monitor_account = optional(map(object({
      name               = string
      monitor_account_id = string
    })), {})
    storage_blob = optional(map(object({
      name               = string
      storage_account_id = string
      container_name     = string
    })), {})
    storage_blob_direct = optional(map(object({
      name               = string
      storage_account_id = string
      container_name     = string
    })), {})
    storage_table_direct = optional(map(object({
      name               = string
      storage_account_id = string
      table_name         = string
    })), {})
  })
  description = "DCR destinations keyed with stable names."
}

variable "data_flows" {
  type = map(object({
    streams            = list(string)
    destinations       = list(string)
    built_in_transform = optional(string)
    output_stream      = optional(string)
    transform_kql      = optional(string)
  }))
  description = "DCR data flows keyed by stable names."
}

variable "data_sources" {
  type = object({
    windows_event_log = optional(map(object({
      name           = string
      streams        = list(string)
      x_path_queries = list(string)
    })), {})
    windows_firewall_log = optional(map(object({
      name    = string
      streams = list(string)
    })), {})
    syslog = optional(map(object({
      name           = string
      streams        = list(string)
      facility_names = list(string)
      log_levels     = list(string)
    })), {})
    performance_counter = optional(map(object({
      name                          = string
      streams                       = list(string)
      sampling_frequency_in_seconds = number
      counter_specifiers            = list(string)
    })), {})
    extension = optional(map(object({
      name               = string
      streams            = list(string)
      extension_name     = string
      extension_json     = optional(string)
      input_data_sources = optional(list(string))
    })), {})
    iis_log = optional(map(object({
      name            = string
      streams         = list(string)
      log_directories = optional(list(string))
    })), {})
    log_file = optional(map(object({
      name          = string
      streams       = list(string)
      file_patterns = list(string)
      format        = string
      settings = optional(object({
        record_start_timestamp_format = string
      }))
    })), {})
    platform_telemetry = optional(map(object({
      name    = string
      streams = list(string)
    })), {})
    prometheus_forwarder = optional(map(object({
      name    = string
      streams = list(string)
      label_include_filters = optional(map(object({
        label = string
        value = string
      })), {})
    })), {})
    data_import_event_hub = optional(map(object({
      name           = string
      stream         = string
      consumer_group = optional(string)
    })), {})
  })
  description = "Optional DCR data sources keyed by stable names."
  default     = {}
}

variable "stream_declarations" {
  type = map(object({
    columns = map(object({
      type = string
    }))
  }))
  description = "Custom stream declarations keyed by stream name."
  default     = {}
}

variable "identity" {
  type = object({
    type         = string
    identity_ids = optional(set(string), [])
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
  type        = map(string)
  description = "Tags to apply."
  default     = {}
}
