output "id" {
  value = azurerm_monitor_data_collection_endpoint.this.id
}

output "name" {
  value = azurerm_monitor_data_collection_endpoint.this.name
}

output "immutable_id" {
  value = azurerm_monitor_data_collection_endpoint.this.immutable_id
}

output "configuration_access_endpoint" {
  value = azurerm_monitor_data_collection_endpoint.this.configuration_access_endpoint
}

output "logs_ingestion_endpoint" {
  value = azurerm_monitor_data_collection_endpoint.this.logs_ingestion_endpoint
}

output "metrics_ingestion_endpoint" {
  value = azurerm_monitor_data_collection_endpoint.this.metrics_ingestion_endpoint
}
