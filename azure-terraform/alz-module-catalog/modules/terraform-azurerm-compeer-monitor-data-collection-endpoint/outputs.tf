output "id" {
  description = "Resource ID of the data collection endpoint."
  value       = azurerm_monitor_data_collection_endpoint.endpoint.id
}

output "name" {
  description = "Name of the data collection endpoint."
  value       = azurerm_monitor_data_collection_endpoint.endpoint.name
}

output "immutable_id" {
  description = "Immutable ID of the endpoint, referenced by data collection rules."
  value       = azurerm_monitor_data_collection_endpoint.endpoint.immutable_id
}

output "configuration_access_endpoint" {
  description = "URL agents use to fetch their configuration from this endpoint."
  value       = azurerm_monitor_data_collection_endpoint.endpoint.configuration_access_endpoint
}

output "logs_ingestion_endpoint" {
  description = "URL for the Logs Ingestion API against this endpoint."
  value       = azurerm_monitor_data_collection_endpoint.endpoint.logs_ingestion_endpoint
}

output "metrics_ingestion_endpoint" {
  description = "URL for custom metrics ingestion against this endpoint."
  value       = azurerm_monitor_data_collection_endpoint.endpoint.metrics_ingestion_endpoint
}
