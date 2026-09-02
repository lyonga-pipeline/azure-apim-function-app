output "id" {
  description = "Resource ID of the metric alert rule."
  value       = azurerm_monitor_metric_alert.this.id
}
output "name" {
  description = "Name of the metric alert rule."
  value       = azurerm_monitor_metric_alert.this.name
}
