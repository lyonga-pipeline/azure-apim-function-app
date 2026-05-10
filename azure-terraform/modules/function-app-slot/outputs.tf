output "id" {
  value = try(azurerm_windows_function_app_slot.this[0].id, azurerm_linux_function_app_slot.this[0].id)
}

output "default_hostname" {
  value = try(azurerm_windows_function_app_slot.this[0].default_hostname, azurerm_linux_function_app_slot.this[0].default_hostname)
}
