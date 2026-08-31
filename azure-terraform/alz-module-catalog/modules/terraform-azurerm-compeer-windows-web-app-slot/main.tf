resource "azurerm_windows_web_app_slot" "this" {
  name                          = var.name
  app_service_id                = var.app_service_id
  https_only                    = var.https_only
  public_network_access_enabled = var.public_network_access_enabled
  virtual_network_subnet_id     = var.virtual_network_subnet_id
  app_settings                  = var.app_settings
  tags                          = var.tags

  site_config {
    always_on                               = var.site_config.always_on
    ftps_state                              = var.site_config.ftps_state
    http2_enabled                           = var.site_config.http2_enabled
    minimum_tls_version                     = var.site_config.minimum_tls_version
    health_check_path                       = var.site_config.health_check_path
    health_check_eviction_time_in_min       = var.site_config.health_check_eviction_time_in_min
    vnet_route_all_enabled                  = var.site_config.vnet_route_all_enabled
    worker_count                            = var.site_config.worker_count
    app_command_line                        = var.site_config.app_command_line
    container_registry_use_managed_identity = var.site_config.container_registry_use_managed_identity

    dynamic "application_stack" {
      for_each = var.site_config.application_stack == null ? [] : [var.site_config.application_stack]
      content {
        current_stack       = application_stack.value.current_stack
        docker_image_name   = application_stack.value.docker_image_name
        docker_registry_url = application_stack.value.docker_registry_url
        dotnet_version      = application_stack.value.dotnet_version
        dotnet_core_version = application_stack.value.dotnet_core_version
        java_version        = application_stack.value.java_version
        node_version        = application_stack.value.node_version
        php_version         = application_stack.value.php_version
        python              = application_stack.value.python
      }
    }
  }

  dynamic "identity" {
    for_each = var.identity == null ? [] : [var.identity]
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  timeouts {
    create = try(var.timeouts.create, null)
    read   = try(var.timeouts.read, null)
    update = try(var.timeouts.update, null)
    delete = try(var.timeouts.delete, null)
  }
}
