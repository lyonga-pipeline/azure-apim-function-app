# App Service Environment v3. The v1/v2 azurerm_app_service_environment resource
# was removed in azurerm 4.x, so this module manages ASEv3 only.
resource "azurerm_app_service_environment_v3" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name

  # A /24 or larger subnet delegated to Microsoft.Web/hostingEnvironments is
  # required. The subnet is caller-owned; this module does not create it.
  subnet_id = var.subnet_id

  allow_new_private_endpoint_connections = var.allow_new_private_endpoint_connections
  internal_load_balancing_mode           = var.internal_load_balancing_mode
  zone_redundant                         = var.zone_redundant

  dynamic "cluster_setting" {
    for_each = var.cluster_settings
    content {
      name  = cluster_setting.key
      value = cluster_setting.value
    }
  }

  tags = var.tags

  timeouts {
    create = try(var.timeouts.create, "6h")
    update = try(var.timeouts.update, "6h")
    read   = try(var.timeouts.read, "5m")
    delete = try(var.timeouts.delete, "6h")
  }
}
