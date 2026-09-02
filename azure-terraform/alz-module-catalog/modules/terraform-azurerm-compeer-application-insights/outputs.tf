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
