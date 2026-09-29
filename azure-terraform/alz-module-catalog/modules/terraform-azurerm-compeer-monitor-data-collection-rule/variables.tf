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

  validation {
    condition     = var.kind == null ? true : contains(["Linux", "Windows", "AgentDirectToStore", "WorkspaceTransforms"], var.kind)
    error_message = "kind, when set, must be Linux, Windows, AgentDirectToStore, or WorkspaceTransforms."
  }
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

  # Bounds/enums are azurerm_monitor_data_collection_rule's own documented
  # limits, not invented ones.
  validation {
    condition = alltrue([
      for ds in values(var.data_sources.performance_counter) :
      ds.sampling_frequency_in_seconds >= 1 && ds.sampling_frequency_in_seconds <= 1800
    ])
    error_message = "data_sources.performance_counter[*].sampling_frequency_in_seconds must be between 1 and 1800."
  }
  validation {
    condition = alltrue([
      for ds in values(var.data_sources.syslog) :
      alltrue([
        for f in ds.facility_names :
        contains([
          "alert", "*", "audit", "auth", "authpriv", "clock", "cron", "daemon", "ftp", "kern",
          "local0", "local1", "local2", "local3", "local4", "local5", "local6", "local7",
          "lpr", "mail", "mark", "news", "nopri", "ntp", "syslog", "user", "uucp",
        ], f)
      ])
    ])
    error_message = "data_sources.syslog[*].facility_names contains an unsupported facility name."
  }
  validation {
    condition = alltrue([
      for ds in values(var.data_sources.syslog) :
      alltrue([
        for l in ds.log_levels :
        contains(["Debug", "Info", "Notice", "Warning", "Error", "Critical", "Alert", "Emergency", "*"], l)
      ])
    ])
    error_message = "data_sources.syslog[*].log_levels contains an unsupported log level."
  }
}

variable "stream_declarations" {
  type = map(object({
    columns = map(object({
      type = string
    }))
  }))
  description = "Custom stream declarations keyed by stream name."
  default     = {}

  validation {
    condition = alltrue([
      for sd in values(var.stream_declarations) :
      alltrue([for col in values(sd.columns) : contains(["string", "int", "long", "real", "boolean", "datetime", "dynamic"], col.type)])
    ])
    error_message = "stream_declarations[*].columns[*].type must be one of string, int, long, real, boolean, datetime, dynamic."
  }
}

variable "identity" {
  type = object({
    type         = string
    identity_ids = optional(set(string), [])
  })
  default = null

  validation {
    condition     = var.identity == null ? true : contains(["SystemAssigned", "UserAssigned"], var.identity.type)
    error_message = "identity.type must be SystemAssigned or UserAssigned."
  }
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
