output "webapp_id" {
  description = "The ID of the Windows Web App."
  value       = azurerm_windows_web_app.windows_web_app.id
}

output "webapp_principal_id" {
  description = "The Principle ID associated with managed service identity"
  value = azurerm_windows_web_app.windows_web_app.identity.0.principal_id
}

output "webapp_tenant_id" {
  description = "The Principle ID associated with managed service identity"
  value = azurerm_windows_web_app.windows_web_app.identity.0.tenant_id
}