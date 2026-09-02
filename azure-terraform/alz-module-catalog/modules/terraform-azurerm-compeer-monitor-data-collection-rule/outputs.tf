output "id" {
  description = "Resource ID of the data collection rule."
  value       = azurerm_monitor_data_collection_rule.this.id
}

output "name" {
  description = "Name of the data collection rule."
  value       = azurerm_monitor_data_collection_rule.this.name
}

output "immutable_id" {
  description = "Immutable ID of the data collection rule."
  value       = azurerm_monitor_data_collection_rule.this.immutable_id
}

output "identity_principal_id" {
  description = "Principal ID of the rule's system-assigned managed identity (null if none), for RBAC grants."
  value       = try(azurerm_monitor_data_collection_rule.this.identity[0].principal_id, null)
}
