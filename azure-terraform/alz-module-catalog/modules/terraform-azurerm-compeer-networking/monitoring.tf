// data "azurerm_monitor_diagnostic_categories" "main" {
//   resource_id = azurerm_virtual_network.vnet.id
// }


// resource "azurerm_monitor_diagnostic_setting" "main" {
//   name                           = var.diagnostic_setting_name
//   target_resource_id             = azurerm_virtual_network.vnet.id
//   log_analytics_workspace_id     = var.log_analytics_workspace_id
//   log_analytics_destination_type = var.log_analytics_destination_type

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