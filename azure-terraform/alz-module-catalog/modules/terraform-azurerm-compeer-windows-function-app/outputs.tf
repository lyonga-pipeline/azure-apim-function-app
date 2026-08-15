output "windows_function_id" {
  description = "The ID of the Windows Web App."
  value       = azurerm_windows_function_app.windows_function_app.id
}

output "windows_function_name" {
  description = "The name of the Windows function App."
  value       = azurerm_windows_function_app.windows_function_app.name
}

output "principal_id" {
  description = "The Principle ID associated with managed service identity"
  value       = azurerm_windows_function_app.windows_function_app.identity[0].principal_id
  ##value  = azurerm_windows_function_app.windows_function_app.identity.principal_id

}

output "name" {
  value = var.name
}

output "resource_group_name" {
  value = var.resource_group_name
}