output "id" {
  value = try(azurerm_windows_web_app_slot.this[0].id, azurerm_linux_web_app_slot.this[0].id)
}

output "default_hostname" {
  value = try(azurerm_windows_web_app_slot.this[0].default_hostname, azurerm_linux_web_app_slot.this[0].default_hostname)
}
