resource "azurerm_service_plan" "this" {
  name                         = var.name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  os_type                      = var.os_type
  sku_name                     = var.sku_name
  maximum_elastic_worker_count = var.maximum_elastic_worker_count
  per_site_scaling_enabled     = var.per_site_scaling_enabled
  worker_count                 = var.worker_count
  zone_balancing_enabled       = var.zone_balancing_enabled
  tags                         = var.tags
}
