output "id" {
  description = "Resource ID of the data collection rule association."
  value       = azurerm_monitor_data_collection_rule_association.this.id
}

output "name" {
  description = "Name of the data collection rule association."
  value       = azurerm_monitor_data_collection_rule_association.this.name
}
