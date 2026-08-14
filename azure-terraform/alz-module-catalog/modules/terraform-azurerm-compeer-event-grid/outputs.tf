output "eventgrid_id" {
  value       = azurerm_eventgrid_topic.main.id
  description = "The EventGrid Topic ID."
}

output "eventgrid_endpoint" {
  value       = azurerm_eventgrid_topic.main.endpoint
  description = "The Endpoint associated with the EventGrid Topic."
}

output "eventgrid_primary_access_key" {
  value       = azurerm_eventgrid_topic.main.primary_access_key
  description = "The Primary Shared Access Key associated with the EventGrid Topic."
  sensitive   = true
}

output "eventgrid_secondary_access_key" {
  value       = azurerm_eventgrid_topic.main.secondary_access_key
  description = "The Secondary Shared Access Key associated with the EventGrid Topic."
  sensitive   = true
}

output "eventgrid_subscription_id" {
  description = "Event grid subscription ID's"
  value = {
    for key, subscription in azurerm_eventgrid_event_subscription.subscription : key => subscription.id
  }
}

output "principal_id" {
  value       = azurerm_eventgrid_topic.main.identity[0].principal_id
  description = "Event grid topic principal ID's"
}
