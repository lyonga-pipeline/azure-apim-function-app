output "id" {
  description = "Resource ID of the Linux Web App."
  value       = azurerm_linux_web_app.linux_web_app.id
}

output "name" {
  description = "Name of the Linux Web App."
  value       = azurerm_linux_web_app.linux_web_app.name
}

output "default_hostname" {
  description = "Default hostname of the Linux Web App."
  value       = azurerm_linux_web_app.linux_web_app.default_hostname
}

output "outbound_ip_addresses" {
  description = "Comma-separated outbound IP addresses."
  value       = azurerm_linux_web_app.linux_web_app.outbound_ip_addresses
}

output "possible_outbound_ip_addresses" {
  description = "All possible outbound IP addresses (includes scale-out)."
  value       = azurerm_linux_web_app.linux_web_app.possible_outbound_ip_addresses
}

output "identity_principal_id" {
  description = "Principal ID of the app's system-assigned identity, when enabled."
  value       = try(azurerm_linux_web_app.linux_web_app.identity[0].principal_id, null)
}
