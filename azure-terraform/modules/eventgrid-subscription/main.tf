locals {
  endpoint_count = length(compact([
    var.webhook_endpoint == null ? null : "webhook",
    var.azure_function_endpoint == null ? null : "function",
    var.storage_queue_endpoint == null ? null : "storage_queue",
    var.eventhub_endpoint_id,
    var.hybrid_connection_endpoint_id,
    var.service_bus_queue_endpoint_id,
    var.service_bus_topic_endpoint_id,
  ]))
}

resource "azurerm_eventgrid_event_subscription" "this" {
  name                                 = var.name
  scope                                = var.scope
  included_event_types                 = var.included_event_types
  event_delivery_schema                = var.event_delivery_schema
  labels                               = var.labels
  expiration_time_utc                  = var.expiration_time_utc
  advanced_filtering_on_arrays_enabled = var.advanced_filtering_on_arrays_enabled
  eventhub_endpoint_id                 = var.eventhub_endpoint_id
  hybrid_connection_endpoint_id        = var.hybrid_connection_endpoint_id
  service_bus_queue_endpoint_id        = var.service_bus_queue_endpoint_id
  service_bus_topic_endpoint_id        = var.service_bus_topic_endpoint_id

  subject_filter {
    subject_begins_with = try(var.subject_filter.subject_begins_with, null)
    subject_ends_with   = try(var.subject_filter.subject_ends_with, null)
    case_sensitive      = try(var.subject_filter.case_sensitive, false)
  }

  dynamic "advanced_filter" {
    for_each = var.advanced_filter == null ? [] : [var.advanced_filter]
    content {
      dynamic "bool_equals" {
        for_each = try(advanced_filter.value.bool_equals, [])
        content {
          key   = bool_equals.value.key
          value = bool_equals.value.value
        }
      }

      dynamic "is_not_null" {
        for_each = try(advanced_filter.value.is_not_null, [])
        content {
          key = is_not_null.value.key
        }
      }

      dynamic "is_null_or_undefined" {
        for_each = try(advanced_filter.value.is_null_or_undefined, [])
        content {
          key = is_null_or_undefined.value.key
        }
      }

      dynamic "number_greater_than" {
        for_each = try(advanced_filter.value.number_greater_than, [])
        content {
          key   = number_greater_than.value.key
          value = number_greater_than.value.value
        }
      }

      dynamic "number_greater_than_or_equals" {
        for_each = try(advanced_filter.value.number_greater_than_or_equals, [])
        content {
          key   = number_greater_than_or_equals.value.key
          value = number_greater_than_or_equals.value.value
        }
      }

      dynamic "number_in" {
        for_each = try(advanced_filter.value.number_in, [])
        content {
          key    = number_in.value.key
          values = number_in.value.values
        }
      }

      dynamic "number_in_range" {
        for_each = try(advanced_filter.value.number_in_range, [])
        content {
          key    = number_in_range.value.key
          values = number_in_range.value.values
        }
      }

      dynamic "number_less_than" {
        for_each = try(advanced_filter.value.number_less_than, [])
        content {
          key   = number_less_than.value.key
          value = number_less_than.value.value
        }
      }

      dynamic "number_less_than_or_equals" {
        for_each = try(advanced_filter.value.number_less_than_or_equals, [])
        content {
          key   = number_less_than_or_equals.value.key
          value = number_less_than_or_equals.value.value
        }
      }

      dynamic "number_not_in" {
        for_each = try(advanced_filter.value.number_not_in, [])
        content {
          key    = number_not_in.value.key
          values = number_not_in.value.values
        }
      }

      dynamic "number_not_in_range" {
        for_each = try(advanced_filter.value.number_not_in_range, [])
        content {
          key    = number_not_in_range.value.key
          values = number_not_in_range.value.values
        }
      }

      dynamic "string_begins_with" {
        for_each = try(advanced_filter.value.string_begins_with, [])
        content {
          key    = string_begins_with.value.key
          values = string_begins_with.value.values
        }
      }

      dynamic "string_contains" {
        for_each = try(advanced_filter.value.string_contains, [])
        content {
          key    = string_contains.value.key
          values = string_contains.value.values
        }
      }

      dynamic "string_ends_with" {
        for_each = try(advanced_filter.value.string_ends_with, [])
        content {
          key    = string_ends_with.value.key
          values = string_ends_with.value.values
        }
      }

      dynamic "string_in" {
        for_each = try(advanced_filter.value.string_in, [])
        content {
          key    = string_in.value.key
          values = string_in.value.values
        }
      }

      dynamic "string_not_begins_with" {
        for_each = try(advanced_filter.value.string_not_begins_with, [])
        content {
          key    = string_not_begins_with.value.key
          values = string_not_begins_with.value.values
        }
      }

      dynamic "string_not_contains" {
        for_each = try(advanced_filter.value.string_not_contains, [])
        content {
          key    = string_not_contains.value.key
          values = string_not_contains.value.values
        }
      }

      dynamic "string_not_ends_with" {
        for_each = try(advanced_filter.value.string_not_ends_with, [])
        content {
          key    = string_not_ends_with.value.key
          values = string_not_ends_with.value.values
        }
      }

      dynamic "string_not_in" {
        for_each = try(advanced_filter.value.string_not_in, [])
        content {
          key    = string_not_in.value.key
          values = string_not_in.value.values
        }
      }
    }
  }

  dynamic "webhook_endpoint" {
    for_each = var.webhook_endpoint == null ? [] : [var.webhook_endpoint]
    content {
      url                               = webhook_endpoint.value.url
      active_directory_app_id_or_uri    = try(webhook_endpoint.value.active_directory_app_id_or_uri, null)
      active_directory_tenant_id        = try(webhook_endpoint.value.active_directory_tenant_id, null)
      max_events_per_batch              = try(webhook_endpoint.value.max_events_per_batch, null)
      preferred_batch_size_in_kilobytes = try(webhook_endpoint.value.preferred_batch_size_in_kilobytes, null)
    }
  }

  dynamic "azure_function_endpoint" {
    for_each = var.azure_function_endpoint == null ? [] : [var.azure_function_endpoint]
    content {
      function_id                       = azure_function_endpoint.value.function_id
      max_events_per_batch              = try(azure_function_endpoint.value.max_events_per_batch, null)
      preferred_batch_size_in_kilobytes = try(azure_function_endpoint.value.preferred_batch_size_in_kilobytes, null)
    }
  }

  dynamic "storage_queue_endpoint" {
    for_each = var.storage_queue_endpoint == null ? [] : [var.storage_queue_endpoint]
    content {
      storage_account_id                    = storage_queue_endpoint.value.storage_account_id
      queue_name                            = storage_queue_endpoint.value.queue_name
      queue_message_time_to_live_in_seconds = try(storage_queue_endpoint.value.queue_message_time_to_live_in_seconds, null)
    }
  }

  dynamic "storage_blob_dead_letter_destination" {
    for_each = var.dead_letter_destination == null ? [] : [var.dead_letter_destination]
    content {
      storage_account_id          = storage_blob_dead_letter_destination.value.storage_account_id
      storage_blob_container_name = storage_blob_dead_letter_destination.value.storage_blob_container_name
    }
  }

  dynamic "retry_policy" {
    for_each = var.retry_policy == null ? [] : [var.retry_policy]
    content {
      event_time_to_live    = retry_policy.value.event_time_to_live
      max_delivery_attempts = retry_policy.value.max_delivery_attempts
    }
  }

  dynamic "delivery_identity" {
    for_each = var.delivery_identity == null ? [] : [var.delivery_identity]
    content {
      type                   = delivery_identity.value.type
      user_assigned_identity = try(delivery_identity.value.user_assigned_identity, null)
    }
  }

  dynamic "dead_letter_identity" {
    for_each = var.dead_letter_identity == null ? [] : [var.dead_letter_identity]
    content {
      type                   = dead_letter_identity.value.type
      user_assigned_identity = try(dead_letter_identity.value.user_assigned_identity, null)
    }
  }

  dynamic "delivery_property" {
    for_each = var.delivery_properties
    content {
      header_name  = delivery_property.value.header_name
      type         = delivery_property.value.type
      secret       = try(delivery_property.value.secret, null)
      source_field = try(delivery_property.value.source_field, null)
      value        = try(delivery_property.value.value, null)
    }
  }

  lifecycle {
    precondition {
      condition     = local.endpoint_count == 1
      error_message = "Set exactly one destination endpoint for the Event Grid subscription."
    }
    precondition {
      condition     = var.dead_letter_identity == null || var.dead_letter_destination != null
      error_message = "dead_letter_identity requires dead_letter_destination."
    }
    precondition {
      condition = (
        var.delivery_identity == null ||
        var.delivery_identity.type != "UserAssigned" ||
        try(var.delivery_identity.user_assigned_identity, null) != null
      )
      error_message = "delivery_identity.user_assigned_identity is required when delivery_identity.type is UserAssigned."
    }
    precondition {
      condition = (
        var.dead_letter_identity == null ||
        var.dead_letter_identity.type != "UserAssigned" ||
        try(var.dead_letter_identity.user_assigned_identity, null) != null
      )
      error_message = "dead_letter_identity.user_assigned_identity is required when dead_letter_identity.type is UserAssigned."
    }
  }
}
