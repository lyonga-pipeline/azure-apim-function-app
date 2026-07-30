locals {
  is_linux          = lower(var.os_type) == "linux"
  is_windows        = lower(var.os_type) == "windows"
  service_plan_name = coalesce(var.service_plan_name, "${var.name}-plan")
  app_service_id    = local.is_linux ? azurerm_linux_web_app.this[0].id : azurerm_windows_web_app.this[0].id
  app_service_name  = local.is_linux ? azurerm_linux_web_app.this[0].name : azurerm_windows_web_app.this[0].name
  default_hostname  = local.is_linux ? azurerm_linux_web_app.this[0].default_hostname : azurerm_windows_web_app.this[0].default_hostname
  identity          = local.is_linux ? azurerm_linux_web_app.this[0].identity : azurerm_windows_web_app.this[0].identity
  outbound_ips      = local.is_linux ? azurerm_linux_web_app.this[0].outbound_ip_addresses : azurerm_windows_web_app.this[0].outbound_ip_addresses
}

resource "azurerm_service_plan" "this" {
  name                         = local.service_plan_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  os_type                      = local.is_linux ? "Linux" : "Windows"
  sku_name                     = var.service_plan_sku_name
  worker_count                 = var.worker_count
  maximum_elastic_worker_count = var.maximum_elastic_worker_count
  per_site_scaling_enabled     = var.per_site_scaling_enabled
  zone_balancing_enabled       = var.zone_balancing_enabled
  tags                         = var.tags
}

resource "azurerm_linux_web_app" "this" {
  count = local.is_linux ? 1 : 0

  name                                           = var.name
  resource_group_name                            = var.resource_group_name
  location                                       = var.location
  service_plan_id                                = azurerm_service_plan.this.id
  public_network_access_enabled                  = var.public_network_access_enabled
  https_only                                     = var.https_only
  enabled                                        = var.enabled
  client_affinity_enabled                        = var.client_affinity_enabled
  ftp_publish_basic_authentication_enabled       = var.ftp_publish_basic_authentication_enabled
  webdeploy_publish_basic_authentication_enabled = var.webdeploy_publish_basic_authentication_enabled
  app_settings                                   = var.app_settings
  tags                                           = var.tags

  dynamic "identity" {
    for_each = var.identity == null ? [] : [var.identity]
    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  site_config {
    always_on               = coalesce(var.site_config.always_on, true)
    ftps_state              = coalesce(var.site_config.ftps_state, "Disabled")
    health_check_path       = var.site_config.health_check_path
    http2_enabled           = coalesce(var.site_config.http2_enabled, true)
    minimum_tls_version     = coalesce(var.site_config.minimum_tls_version, "1.2")
    scm_minimum_tls_version = coalesce(var.site_config.scm_minimum_tls_version, "1.2")
    use_32_bit_worker       = var.site_config.use_32_bit_worker
    websockets_enabled      = var.site_config.websockets_enabled
    vnet_route_all_enabled  = coalesce(var.site_config.vnet_route_all_enabled, var.virtual_network_subnet_id != null)
    app_command_line        = var.site_config.app_command_line

    dynamic "application_stack" {
      for_each = var.site_config.application_stack == null ? [] : [var.site_config.application_stack]
      content {
        docker_image_name        = application_stack.value.docker_image_name
        docker_registry_url      = application_stack.value.docker_registry_url
        docker_registry_username = application_stack.value.docker_registry_username
        docker_registry_password = application_stack.value.docker_registry_password
        dotnet_version           = application_stack.value.dotnet_version
        go_version               = application_stack.value.go_version
        java_server              = application_stack.value.java_server
        java_server_version      = application_stack.value.java_server_version
        java_version             = application_stack.value.java_version
        node_version             = application_stack.value.node_version
        php_version              = application_stack.value.php_version
        python_version           = application_stack.value.python_version
      }
    }
  }
}

resource "azurerm_windows_web_app" "this" {
  count = local.is_windows ? 1 : 0

  name                                           = var.name
  resource_group_name                            = var.resource_group_name
  location                                       = var.location
  service_plan_id                                = azurerm_service_plan.this.id
  public_network_access_enabled                  = var.public_network_access_enabled
  https_only                                     = var.https_only
  enabled                                        = var.enabled
  client_affinity_enabled                        = var.client_affinity_enabled
  ftp_publish_basic_authentication_enabled       = var.ftp_publish_basic_authentication_enabled
  webdeploy_publish_basic_authentication_enabled = var.webdeploy_publish_basic_authentication_enabled
  app_settings                                   = var.app_settings
  tags                                           = var.tags

  dynamic "identity" {
    for_each = var.identity == null ? [] : [var.identity]
    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  site_config {
    always_on               = coalesce(var.site_config.always_on, true)
    ftps_state              = coalesce(var.site_config.ftps_state, "Disabled")
    health_check_path       = var.site_config.health_check_path
    http2_enabled           = coalesce(var.site_config.http2_enabled, true)
    minimum_tls_version     = coalesce(var.site_config.minimum_tls_version, "1.2")
    scm_minimum_tls_version = coalesce(var.site_config.scm_minimum_tls_version, "1.2")
    use_32_bit_worker       = var.site_config.use_32_bit_worker
    websockets_enabled      = var.site_config.websockets_enabled
    vnet_route_all_enabled  = coalesce(var.site_config.vnet_route_all_enabled, var.virtual_network_subnet_id != null)
    app_command_line        = var.site_config.app_command_line

    dynamic "application_stack" {
      for_each = var.site_config.application_stack == null ? [] : [var.site_config.application_stack]
      content {
        current_stack                = application_stack.value.current_stack
        docker_image_name            = application_stack.value.docker_image_name
        docker_registry_url          = application_stack.value.docker_registry_url
        docker_registry_username     = application_stack.value.docker_registry_username
        docker_registry_password     = application_stack.value.docker_registry_password
        dotnet_core_version          = application_stack.value.dotnet_core_version
        dotnet_version               = application_stack.value.dotnet_version
        java_container               = application_stack.value.java_container
        java_container_version       = application_stack.value.java_container_version
        java_embedded_server_enabled = application_stack.value.java_embedded_server_enabled
        java_version                 = application_stack.value.java_version
        node_version                 = application_stack.value.node_version
        php_version                  = application_stack.value.php_version
        python                       = application_stack.value.python
        tomcat_version               = application_stack.value.tomcat_version
      }
    }
  }
}

resource "azurerm_app_service_virtual_network_swift_connection" "this" {
  count = var.virtual_network_subnet_id == null ? 0 : 1

  app_service_id = local.app_service_id
  subnet_id      = var.virtual_network_subnet_id
}
