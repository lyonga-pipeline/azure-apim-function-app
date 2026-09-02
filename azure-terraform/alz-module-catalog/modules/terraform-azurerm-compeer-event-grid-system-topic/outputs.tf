output "eventgrid_id" {
  value       = azurerm_eventgrid_system_topic.system_topic.id
  description = "The EventGrid Topic ID."
}

output "principal_id" {
  value       = try(azurerm_eventgrid_system_topic.system_topic.identity[0].principal_id, null)
  description = "Principal ID of the system topic's system-assigned managed identity (null if none), for RBAC grants."
}

output "id" {
  description = "Resource ID of the Event Grid system topic. Stable alias for eventgrid_id."
  value       = azurerm_eventgrid_system_topic.system_topic.id
}
output "name" {
  description = "Name of the Event Grid system topic."
  value       = azurerm_eventgrid_system_topic.system_topic.name
}
