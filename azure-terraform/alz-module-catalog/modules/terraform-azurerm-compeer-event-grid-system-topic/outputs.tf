output "eventgrid_id" {
  value       = azurerm_eventgrid_system_topic.system_topic.id
  description = "The EventGrid Topic ID."
}

output "principal_id" {
  value       = azurerm_eventgrid_system_topic.system_topic.identity[0].principal_id
  description = "Event grid topic principal ID's"
}
