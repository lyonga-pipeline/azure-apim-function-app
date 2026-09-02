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

output "id" {
  description = "Resource ID of the Event Grid namespace. Stable alias for eventgrid_namespace_id."
  value       = azurerm_eventgrid_namespace.main.id
}

output "name" {
  description = "Name of the Event Grid namespace."
  value       = azurerm_eventgrid_namespace.main.name
}

output "identity_principal_id" {
  description = "Principal ID of the namespace's system-assigned managed identity (null if none), for RBAC grants."
  value       = try(azurerm_eventgrid_namespace.main.identity[0].principal_id, null)
}
