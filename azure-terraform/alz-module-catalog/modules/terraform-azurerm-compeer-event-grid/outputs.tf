output "eventgrid_id" {
  description = "Resource ID of the Event Grid topic."
  value       = azurerm_eventgrid_topic.main.id
}
output "eventgrid_endpoint" {
  description = "Endpoint URL of the Event Grid topic."
  value       = azurerm_eventgrid_topic.main.endpoint
}
output "eventgrid_primary_access_key" {
  description = "Primary access key for the Event Grid topic (sensitive)."
  value       = azurerm_eventgrid_topic.main.primary_access_key
  sensitive   = true
}
output "eventgrid_secondary_access_key" {
  description = "Secondary access key for the Event Grid topic (sensitive)."
  value       = azurerm_eventgrid_topic.main.secondary_access_key
  sensitive   = true
}
output "principal_id" {
  description = "Principal ID of the topic's system-assigned managed identity (null if none), for RBAC grants."
  value       = try(azurerm_eventgrid_topic.main.identity[0].principal_id, null)
}

output "id" {
  description = "Resource ID of the Event Grid topic. Stable alias for eventgrid_id."
  value       = azurerm_eventgrid_topic.main.id
}
output "name" {
  description = "Name of the Event Grid topic."
  value       = azurerm_eventgrid_topic.main.name
}
output "endpoint" {
  description = "Endpoint URL of the Event Grid topic. Stable alias for eventgrid_endpoint."
  value       = azurerm_eventgrid_topic.main.endpoint
}
