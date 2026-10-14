resource "azurerm_application_insights" "application_insights" {
  name                                 = var.name
  resource_group_name                  = var.resource_group_name
  location                             = var.location
  application_type                     = var.application_type
  daily_data_cap_in_gb                 = var.daily_data_cap_in_gb
  daily_data_cap_notifications_enabled = !coalesce(var.daily_data_cap_notifications_disabled, false)
  retention_in_days                    = var.retention_in_days
  sampling_percentage                  = var.sampling_percentage
  ip_masking_enabled                   = !coalesce(var.disable_ip_masking, false)
  workspace_id                         = var.workspace_id
  local_authentication_enabled         = !coalesce(var.local_authentication_disabled, false)
  internet_ingestion_enabled           = var.internet_ingestion_enabled
  internet_query_enabled               = var.internet_query_enabled
  force_customer_storage_for_profiler  = var.force_customer_storage_for_profiler
  tags                                 = var.tags
}
