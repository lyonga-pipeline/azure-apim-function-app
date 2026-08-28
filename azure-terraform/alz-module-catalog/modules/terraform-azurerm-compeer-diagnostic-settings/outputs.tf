output "id" {
  description = "The diagnostic setting ID."
  value       = azurerm_monitor_diagnostic_setting.this.id
}

output "name" {
  description = "The diagnostic setting name."
  value       = azurerm_monitor_diagnostic_setting.this.name
}

output "target_resource_id" {
  description = "The resource ID diagnostic settings are attached to."
  value       = azurerm_monitor_diagnostic_setting.this.target_resource_id
}

output "destinations" {
  description = "Configured diagnostic destinations."
  value = {
    log_analytics_workspace_id     = azurerm_monitor_diagnostic_setting.this.log_analytics_workspace_id
    log_analytics_destination_type = azurerm_monitor_diagnostic_setting.this.log_analytics_destination_type
    storage_account_id             = azurerm_monitor_diagnostic_setting.this.storage_account_id
    eventhub_authorization_rule_id = azurerm_monitor_diagnostic_setting.this.eventhub_authorization_rule_id
    eventhub_name                  = azurerm_monitor_diagnostic_setting.this.eventhub_name
    partner_solution_id            = azurerm_monitor_diagnostic_setting.this.partner_solution_id
  }
}
