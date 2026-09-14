output "id" {
  description = "The diagnostic setting ID."
  value       = azurerm_monitor_diagnostic_setting.setting.id
}

output "name" {
  description = "The diagnostic setting name."
  value       = azurerm_monitor_diagnostic_setting.setting.name
}

output "target_resource_id" {
  description = "The resource ID diagnostic settings are attached to."
  value       = azurerm_monitor_diagnostic_setting.setting.target_resource_id
}

output "destinations" {
  description = "Configured diagnostic destinations."
  value = {
    log_analytics_workspace_id     = azurerm_monitor_diagnostic_setting.setting.log_analytics_workspace_id
    log_analytics_destination_type = azurerm_monitor_diagnostic_setting.setting.log_analytics_destination_type
    storage_account_id             = azurerm_monitor_diagnostic_setting.setting.storage_account_id
    eventhub_authorization_rule_id = azurerm_monitor_diagnostic_setting.setting.eventhub_authorization_rule_id
    eventhub_name                  = azurerm_monitor_diagnostic_setting.setting.eventhub_name
    partner_solution_id            = azurerm_monitor_diagnostic_setting.setting.partner_solution_id
  }
}
