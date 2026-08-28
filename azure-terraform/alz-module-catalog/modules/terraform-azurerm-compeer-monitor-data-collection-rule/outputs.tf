output "id" {
  value = azurerm_monitor_data_collection_rule.this.id
}

output "name" {
  value = azurerm_monitor_data_collection_rule.this.name
}

output "immutable_id" {
  value = azurerm_monitor_data_collection_rule.this.immutable_id
}

output "identity_principal_id" {
  value = try(azurerm_monitor_data_collection_rule.this.identity[0].principal_id, null)
}
