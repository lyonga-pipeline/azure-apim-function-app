locals {
  is_windows = lower(var.os_type) == "windows"
  is_linux   = lower(var.os_type) == "linux"
  site_config_defaults = {
    ftps_state              = "Disabled"
    http2_enabled           = true
    minimum_tls_version     = "1.2"
    scm_minimum_tls_version = "1.2"
  }
  effective_site_config = merge(local.site_config_defaults, var.site_config)
}

resource "azurerm_windows_web_app_slot" "this" {
  count = local.is_windows ? 1 : 0

  name                          = var.name
  app_service_id                = var.app_service_id
  service_plan_id               = var.service_plan_id
  public_network_access_enabled = var.public_network_access_enabled
  https_only                    = var.https_only
  enabled                       = var.enabled
  client_affinity_enabled       = var.client_affinity_enabled
  client_certificate_enabled    = var.client_certificate_enabled
  client_certificate_mode       = var.client_certificate_mode
  app_settings                  = var.app_settings
  tags                          = var.tags

  dynamic "identity" {
    for_each = var.identity == null ? [] : [var.identity]
    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  site_config {
    always_on               = try(local.effective_site_config.always_on, null)
    ftps_state              = try(local.effective_site_config.ftps_state, null)
    health_check_path       = try(local.effective_site_config.health_check_path, null)
    http2_enabled           = try(local.effective_site_config.http2_enabled, null)
    minimum_tls_version     = try(local.effective_site_config.minimum_tls_version, null)
    scm_minimum_tls_version = try(local.effective_site_config.scm_minimum_tls_version, null)
    use_32_bit_worker       = try(local.effective_site_config.use_32_bit_worker, null)
    websockets_enabled      = try(local.effective_site_config.websockets_enabled, null)
    vnet_route_all_enabled  = try(local.effective_site_config.vnet_route_all_enabled, null)
    app_command_line        = try(local.effective_site_config.app_command_line, null)

    dynamic "application_stack" {
      for_each = try(local.effective_site_config.application_stack, null) == null ? [] : [local.effective_site_config.application_stack]
      content {
        current_stack                = try(application_stack.value.current_stack, null)
        docker_image_name            = try(application_stack.value.docker_image_name, null)
        docker_registry_url          = try(application_stack.value.docker_registry_url, null)
        docker_registry_username     = try(application_stack.value.docker_registry_username, null)
        docker_registry_password     = try(application_stack.value.docker_registry_password, null)
        dotnet_core_version          = try(application_stack.value.dotnet_core_version, null)
        dotnet_version               = try(application_stack.value.dotnet_version, null)
        java_container               = try(application_stack.value.java_container, null)
        java_container_version       = try(application_stack.value.java_container_version, null)
        java_embedded_server_enabled = try(application_stack.value.java_embedded_server_enabled, null)
        java_version                 = try(application_stack.value.java_version, null)
        node_version                 = try(application_stack.value.node_version, null)
        php_version                  = try(application_stack.value.php_version, null)
        python                       = try(application_stack.value.python, null)
        tomcat_version               = try(application_stack.value.tomcat_version, null)
      }
    }
  }

  dynamic "connection_string" {
    for_each = var.connection_strings
    content {
      name  = connection_string.key
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }
}

resource "azurerm_linux_web_app_slot" "this" {
  count = local.is_linux ? 1 : 0

  name                          = var.name
  app_service_id                = var.app_service_id
  service_plan_id               = var.service_plan_id
  public_network_access_enabled = var.public_network_access_enabled
  https_only                    = var.https_only
  enabled                       = var.enabled
  client_affinity_enabled       = var.client_affinity_enabled
  client_certificate_enabled    = var.client_certificate_enabled
  client_certificate_mode       = var.client_certificate_mode
  app_settings                  = var.app_settings
  tags                          = var.tags

  dynamic "identity" {
    for_each = var.identity == null ? [] : [var.identity]
    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  site_config {
    always_on               = try(local.effective_site_config.always_on, null)
    ftps_state              = try(local.effective_site_config.ftps_state, null)
    health_check_path       = try(local.effective_site_config.health_check_path, null)
    http2_enabled           = try(local.effective_site_config.http2_enabled, null)
    minimum_tls_version     = try(local.effective_site_config.minimum_tls_version, null)
    scm_minimum_tls_version = try(local.effective_site_config.scm_minimum_tls_version, null)
    use_32_bit_worker       = try(local.effective_site_config.use_32_bit_worker, null)
    websockets_enabled      = try(local.effective_site_config.websockets_enabled, null)
    vnet_route_all_enabled  = try(local.effective_site_config.vnet_route_all_enabled, null)
    app_command_line        = try(local.effective_site_config.app_command_line, null)

    dynamic "application_stack" {
      for_each = try(local.effective_site_config.application_stack, null) == null ? [] : [local.effective_site_config.application_stack]
      content {
        docker_image_name        = try(application_stack.value.docker_image_name, null)
        docker_registry_url      = try(application_stack.value.docker_registry_url, null)
        docker_registry_username = try(application_stack.value.docker_registry_username, null)
        docker_registry_password = try(application_stack.value.docker_registry_password, null)
        dotnet_version           = try(application_stack.value.dotnet_version, null)
        go_version               = try(application_stack.value.go_version, null)
        java_server              = try(application_stack.value.java_server, null)
        java_server_version      = try(application_stack.value.java_server_version, null)
        java_version             = try(application_stack.value.java_version, null)
        node_version             = try(application_stack.value.node_version, null)
        php_version              = try(application_stack.value.php_version, null)
        python_version           = try(application_stack.value.python_version, null)
        ruby_version             = try(application_stack.value.ruby_version, null)
      }
    }
  }

  dynamic "connection_string" {
    for_each = var.connection_strings
    content {
      name  = connection_string.key
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }
}
