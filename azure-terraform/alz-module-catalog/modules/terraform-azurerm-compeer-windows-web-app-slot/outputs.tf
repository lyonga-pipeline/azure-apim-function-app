output "id" {
  description = "Resource ID of the deployment slot."
  value       = azurerm_windows_web_app_slot.this.id
}

output "name" {
  description = "Name of the deployment slot."
  value       = azurerm_windows_web_app_slot.this.name
}

output "default_hostname" {
  description = "Default hostname of the slot."
  value       = azurerm_windows_web_app_slot.this.default_hostname
}

output "identity_principal_id" {
  description = "Principal ID of the slot's system-assigned identity, when enabled."
  value       = try(azurerm_windows_web_app_slot.this.identity[0].principal_id, null)
}
