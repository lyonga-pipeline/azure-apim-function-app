output "id" {
  value = try(azurerm_windows_web_app.this[0].id, azurerm_linux_web_app.this[0].id)
}
output "name" {
  value = try(azurerm_windows_web_app.this[0].name, azurerm_linux_web_app.this[0].name)
}
output "default_hostname" {
  value = try(azurerm_windows_web_app.this[0].default_hostname, azurerm_linux_web_app.this[0].default_hostname)
}
output "identity" {
  value = try(azurerm_windows_web_app.this[0].identity, azurerm_linux_web_app.this[0].identity)
}
output "outbound_ip_addresses" {
  value = try(azurerm_windows_web_app.this[0].outbound_ip_addresses, azurerm_linux_web_app.this[0].outbound_ip_addresses)
}
