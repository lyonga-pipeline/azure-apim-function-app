output "service_plan_id" {
  description = "The ID of the Service Plan."
  value       = azurerm_service_plan.service_plan.id
}

output "service_plan_kind" {
  description = "A string representing the Kind of Service Plan."
  value       = azurerm_service_plan.service_plan.kind
}

output "id" {
  description = "Resource ID of the App Service plan. Stable alias for service_plan_id."
  value       = azurerm_service_plan.service_plan.id
}
output "name" {
  description = "Name of the App Service plan."
  value       = azurerm_service_plan.service_plan.name
}
