output "eventgrid_namespace_id" {
  value       = azurerm_eventgrid_namespace.main.id
  description = "The Event Grid Namespace ID."
}

output "eventgrid_namespace_capacity" {
  value       = azurerm_eventgrid_namespace.main.capacity
  description = "The Capacity of the Event Grid Namespace."
}

output "eventgrid_namespace_identity" {
  value       = azurerm_eventgrid_namespace.main.identity
  description = "The Identity configuration of the Event Grid Namespace."
}
