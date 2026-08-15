output "service_plan_id" {
  description = "The ID of the Service Plan."
  value       = azurerm_service_plan.service_plan.id
}

output "service_plan_kind" {
  description = "A string representing the Kind of Service Plan."
  value       = azurerm_service_plan.service_plan.kind
}