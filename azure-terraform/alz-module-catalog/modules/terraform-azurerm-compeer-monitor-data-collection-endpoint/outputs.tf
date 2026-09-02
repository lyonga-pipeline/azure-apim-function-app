output "id" {
  description = "Resource ID of the data collection endpoint."
  value       = azurerm_monitor_data_collection_endpoint.this.id
}

output "name" {
  description = "Name of the data collection endpoint."
  value       = azurerm_monitor_data_collection_endpoint.this.name
}

output "immutable_id" {
  description = "Immutable ID of the endpoint, referenced by data collection rules."
  value       = azurerm_monitor_data_collection_endpoint.this.immutable_id
}

output "configuration_access_endpoint" {
  description = "URL agents use to fetch their configuration from this endpoint."
  value       = azurerm_monitor_data_collection_endpoint.this.configuration_access_endpoint
}

output "logs_ingestion_endpoint" {
  description = "URL for the Logs Ingestion API against this endpoint."
  value       = azurerm_monitor_data_collection_endpoint.this.logs_ingestion_endpoint
}

output "metrics_ingestion_endpoint" {
  description = "URL for custom metrics ingestion against this endpoint."
  value       = azurerm_monitor_data_collection_endpoint.this.metrics_ingestion_endpoint
}
