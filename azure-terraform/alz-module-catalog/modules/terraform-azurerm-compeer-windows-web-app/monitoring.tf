// resource "azurerm_monitor_diagnostic_setting" "main" {
//   name                           = var.diagnostic_setting_name
//   target_resource_id             = azurerm_windows_web_app.windows_web_app.id
//   log_analytics_destination_type = var.log_analytics_destination_type
//   log_analytics_workspace_id     = var.log_analytics_workspace_id
//   enabled_log {
//     category_group = "allLogs"
//   }
//   dynamic "metric" {
//     for_each = local.metrics
//     content {
//       category = metric.key
//     }
//   }
//   lifecycle {
//     ignore_changes = [log_analytics_destination_type]
//   }
// }