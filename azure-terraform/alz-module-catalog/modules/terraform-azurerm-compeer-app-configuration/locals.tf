locals {
  configuration_store_id = var.create_app_config ? azurerm_app_configuration.app_config[0].id : data.azurerm_app_configuration.app_config[0].id
  app_config_endpoint    = var.create_app_config ? azurerm_app_configuration.app_config[0].endpoint : data.azurerm_app_configuration.app_config[0].endpoint

  app_config_feature_id = var.create_app_config_feature ? azurerm_app_configuration_feature.app_config_feature[0].id : null
  app_config_key_id     = var.create_app_config_key ? azurerm_app_configuration_key.app_config_key[0].id : null

  log_categories      = try(data.azurerm_monitor_diagnostic_categories.main.log_category_types, [])
  metrics             = try(data.azurerm_monitor_diagnostic_categories.main.metrics, [])
  log_category_groups = try(data.azurerm_monitor_diagnostic_categories.main.log_category_groups, [])
}