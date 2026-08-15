output "webapp_id" {
  description = "The ID of the Linux Web App."
  value       = azurerm_linux_web_app.linux_web_app.id
}

output "webapp_principal_id" {
  description = "The Principle ID associated with managed service identity"
  value       = azurerm_linux_web_app.linux_web_app.identity.0.principal_id
}