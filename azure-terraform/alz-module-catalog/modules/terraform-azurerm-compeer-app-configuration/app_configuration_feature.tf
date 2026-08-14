/**
## Managing Azure App Configuration Feature
*/
resource "azurerm_app_configuration_feature" "app_config_feature" {
  count                   = var.create_app_config_feature ? 1 : 0
  configuration_store_id  = local.configuration_store_id
  description             = var.feature_description
  enabled                 = var.feature_enabled
  key                     = var.feature_key
  label                   = var.feature_label
  locked                  = var.feature_locked
  name                    = var.feature_name
  percentage_filter_value = var.percentage_filter_value
  tags                    = var.feature_tags
  dynamic "targeting_filter" {
    for_each = var.targeting_filter != null ? [var.targeting_filter] : []
    content {
      default_rollout_percentage = targeting_filter.value.default_rollout_percentage
      users                      = targeting_filter.value.users

      dynamic "groups" {
        for_each = targeting_filter.value.groups != null ? targeting_filter.value.groups : []
        content {
          name               = groups.value.name
          rollout_percentage = groups.value.rollout_percentage
        }
      }
    }
  }
  dynamic "timewindow_filter" {
    for_each = var.timewindow_filter != null ? [var.timewindow_filter] : []
    content {
      start = timewindow_filter.value.start
      end   = timewindow_filter.value.end
    }
  }
}
