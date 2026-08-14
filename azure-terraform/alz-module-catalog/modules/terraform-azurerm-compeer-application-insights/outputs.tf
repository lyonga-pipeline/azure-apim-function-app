output "application_insights_id" {
  description = "The ID of the Application Insights component."
  value       = azurerm_application_insights.application_insights.id
}

output "application_insights_instrumentation_key" {
  description = "The Instrumentation Key of the Application Insights component."
  value       = azurerm_application_insights.application_insights.instrumentation_key
}

output "application_insights_connection_string" {
  description = "The Connection String of the Application Insights component."
  value       = azurerm_application_insights.application_insights.connection_string
}

output "application_insights_name" {
  description = "The Name of the Application Insights component."
  value       = azurerm_application_insights.application_insights.name
}