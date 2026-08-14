locals {
  gateway_ip_configuration_name  = "appgw-${var.app_gateway_name}-gwipc"

  log_categories      = try(data.azurerm_monitor_diagnostic_categories.main.log_category_types, [])
  metrics             = try(data.azurerm_monitor_diagnostic_categories.main.metrics, [])
  log_category_groups = try(data.azurerm_monitor_diagnostic_categories.main.log_category_groups, [])
}