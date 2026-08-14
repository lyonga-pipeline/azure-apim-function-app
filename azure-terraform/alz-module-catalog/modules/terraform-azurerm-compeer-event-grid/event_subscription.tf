resource "azurerm_eventgrid_event_subscription" "subscription" {
  for_each = local.eventgrid_subscription
  name     = each.value.subscription.name
  scope    = azurerm_eventgrid_topic.main.id
  # scope                         = lookup(each.value.subscription, "scope", azurerm_eventgrid_topic.main.id)
  event_delivery_schema         = lookup(each.value.subscription, "event_delivery_schema", "EventGridSchema")
  eventhub_endpoint_id          = lookup(each.value.subscription, "eventhub_endpoint_id", null)
  hybrid_connection_endpoint_id = lookup(each.value.subscription, "hybrid_connection_endpoint_id", null)
  service_bus_queue_endpoint_id = lookup(each.value.subscription, "service_bus_queue_endpoint_id", null)
  service_bus_topic_endpoint_id = lookup(each.value.subscription, "service_bus_topic_endpoint_id", null)


  dynamic "storage_queue_endpoint" {
    for_each = each.value.subscription.storage_queue_endpoint != null ? [1] : []
    content {
      storage_account_id = each.value.subscription.storage_queue_endpoint.storage_account_id
      queue_name         = each.value.subscription.storage_queue_endpoint.queue_name
    }
  }

  dynamic "storage_blob_dead_letter_destination" {
    for_each = each.value.subscription.storage_blob_dead_letter_destination != null ? [1] : []
    content {
      storage_account_id          = each.value.subscription.storage_blob_dead_letter_destination.storage_account_id
      storage_blob_container_name = each.value.subscription.storage_blob_dead_letter_destination.container_name
    }
  }

  dynamic "delivery_property" {
    for_each = each.value.subscription.delivery_property != null ? [1] : []
    content {
      header_name = each.value.subscription.delivery_property.header_name
      type        = each.value.subscription.delivery_property.type
      value       = each.value.subscription.delivery_property.value
      secret      = each.value.subscription.delivery_property.secret
    }
  }

  dynamic "dead_letter_identity" {
    for_each = each.value.subscription.dead_letter_identity != null ? [1] : []
    content {
       type        = each.value.subscription.dead_letter_identity.type
    }
  }

  dynamic "delivery_identity" {
    for_each = each.value.subscription.delivery_identity != null ? [1] : []
    content {
       type        = each.value.subscription.delivery_identity.type
    }
  }

  dynamic "azure_function_endpoint" {
    for_each = each.value.subscription.azure_function_endpoint != null ? [1] : []
    content {
      function_id = each.value.subscription.azure_function_endpoint.function_id
    }
  }

  dynamic "webhook_endpoint" {
    for_each = each.value.subscription.webhook_endpoint != null ? [1] : []
    content {
      url                               = each.value.subscription.webhook_endpoint.url
      max_events_per_batch              = each.value.subscription.webhook_endpoint.max_events_per_batch != null ? each.value.subscription.webhook_endpoint.max_events_per_batch : 0
      preferred_batch_size_in_kilobytes = each.value.subscription.webhook_endpoint.preferred_batch_size_in_kilobytes != null ? each.value.subscription.webhook_endpoint.preferred_batch_size_in_kilobytes : 0
      active_directory_app_id_or_uri    = each.value.subscription.webhook_endpoint.active_directory_app_id_or_uri != null ? each.value.subscription.webhook_endpoint.active_directory_app_id_or_uri : null
      active_directory_tenant_id        = each.value.subscription.webhook_endpoint.active_directory_tenant_id != null ? each.value.subscription.webhook_endpoint.active_directory_tenant_id : null
    }
  }

  /***
  This module is not covering `subject_filter`, `advanced_filter`, `delivery_identity`, `delivery_property`. 
  This can be added later, when Compeer team has the use-case for it.
 */

}