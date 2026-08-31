output "id" {
  description = "Resource ID of the Windows Web App."
  value       = azurerm_windows_web_app.windows_web_app.id
}

output "name" {
  description = "Name of the Windows Web App."
  value       = azurerm_windows_web_app.windows_web_app.name
}

output "default_hostname" {
  description = "Default hostname of the Windows Web App."
  value       = azurerm_windows_web_app.windows_web_app.default_hostname
}

output "outbound_ip_addresses" {
  description = "Comma-separated outbound IP addresses."
  value       = azurerm_windows_web_app.windows_web_app.outbound_ip_addresses
}

output "identity_principal_id" {
  description = "Principal ID of the app's system-assigned identity, when enabled."
  value       = try(azurerm_windows_web_app.windows_web_app.identity[0].principal_id, null)
}
