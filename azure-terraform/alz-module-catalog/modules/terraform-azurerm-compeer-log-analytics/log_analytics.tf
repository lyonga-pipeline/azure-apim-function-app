resource "azurerm_log_analytics_workspace" "logs" {
  name                                    = var.log_analytics_workspace_name
  location                                = var.location
  resource_group_name                     = var.resource_group_name
  sku                                     = var.log_analytics_sku
  retention_in_days                       = var.log_analytics_retention_in_days
  daily_quota_gb                          = var.log_analytics_daily_quota_gb
  allow_resource_only_permissions         = var.allow_resource_only_permissions
  cmk_for_query_forced                    = var.cmk_for_query_forced
  data_collection_rule_id                 = var.data_collection_rule_id
  immediate_data_purge_on_30_days_enabled = var.immediate_data_purge_on_30_days_enabled
  internet_ingestion_enabled              = var.internet_ingestion_enabled
  internet_query_enabled                  = var.internet_query_enabled
  local_authentication_disabled           = var.local_authentication_disabled
  reservation_capacity_in_gb_per_day      = var.reservation_capacity_in_gb_per_day

  tags = var.tags

  dynamic "identity" {
    for_each = var.identity == null ? [] : [var.identity]
    content {
      type         = identity.value.type
      identity_ids = length(try(identity.value.identity_ids, [])) == 0 ? null : identity.value.identity_ids
    }
  }

  timeouts {
    create = try(var.timeouts.create, null)
    update = try(var.timeouts.update, null)
    read   = try(var.timeouts.read, null)
    delete = try(var.timeouts.delete, null)
  }
}
