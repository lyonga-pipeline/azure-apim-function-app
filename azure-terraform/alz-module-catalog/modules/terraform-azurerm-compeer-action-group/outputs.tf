output "id" {
  description = "Resource ID of the monitor action group."
  value       = azurerm_monitor_action_group.this.id
}
output "name" {
  description = "Name of the monitor action group."
  value       = azurerm_monitor_action_group.this.name
}
output "resource_group_name" {
  description = "Name of the resource group containing the action group."
  value       = azurerm_monitor_action_group.this.resource_group_name
}
output "short_name" {
  description = "Short name of the action group (used as the SMS/email sender label)."
  value       = azurerm_monitor_action_group.this.short_name
}
output "enabled" {
  description = "Whether the action group is enabled."
  value       = azurerm_monitor_action_group.this.enabled
}
