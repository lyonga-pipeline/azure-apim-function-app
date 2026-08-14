output "app_service_environment_id" {
  description = "The ID of the App Service Environment."
  value       = var.create_v3 ? null : azurerm_app_service_environment.app_service_environment[0].id
}

output "app_service_environment_id_v3" {
  description = "The ID of the App Service Environment V3."
  value       = var.create_v3 ? azurerm_app_service_environment_v3.service_environment_v3[0].id : null
}