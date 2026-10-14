output "application_insights_id" {
  description = "The ID of the Application Insights component."
  value       = azurerm_application_insights.application_insights.id
}

output "application_insights_instrumentation_key" {
  sensitive   = true
  description = "The Instrumentation Key of the Application Insights component."
  value       = azurerm_application_insights.application_insights.instrumentation_key
}

output "application_insights_connection_string" {
  sensitive   = true
  description = "The Connection String of the Application Insights component."
  value       = azurerm_application_insights.application_insights.connection_string
}

output "application_insights_name" {
  description = "The Name of the Application Insights component."
  value       = azurerm_application_insights.application_insights.name
}

output "id" {
  description = "Resource ID of the Application Insights component. Stable alias for application_insights_id."
  value       = azurerm_application_insights.application_insights.id
}
output "name" {
  description = "Name of the Application Insights component. Stable alias for application_insights_name."
  value       = azurerm_application_insights.application_insights.name
}
output "app_id" {
  description = "Application ID (used by the Application Insights REST API)."
  value       = azurerm_application_insights.application_insights.app_id
}

output "security_configuration" {
  description = "Non-secret observed telemetry configuration for workload integration checks."
  value = {
    workspace_id                         = azurerm_application_insights.application_insights.workspace_id
    sampling_percentage                  = azurerm_application_insights.application_insights.sampling_percentage
    local_authentication_disabled        = !azurerm_application_insights.application_insights.local_authentication_enabled
    ip_masking_enabled                   = azurerm_application_insights.application_insights.ip_masking_enabled
    daily_data_cap_notifications_enabled = azurerm_application_insights.application_insights.daily_data_cap_notifications_enabled
    internet_ingestion_enabled           = azurerm_application_insights.application_insights.internet_ingestion_enabled
    internet_query_enabled               = azurerm_application_insights.application_insights.internet_query_enabled
  }
}
