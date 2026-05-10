locals {
  is_windows = lower(var.os_type) == "windows"
  is_linux   = lower(var.os_type) == "linux"
}

resource "azurerm_windows_function_app_slot" "this" {
  count = local.is_windows ? 1 : 0

  name                          = var.name
  function_app_id               = var.function_app_id
  storage_account_name          = try(var.storage.account_name, null)
  storage_account_access_key    = try(var.storage.account_access_key, null)
  storage_uses_managed_identity = try(var.storage.uses_managed_identity, null)
  storage_key_vault_secret_id   = try(var.storage.key_vault_secret_id, null)
  public_network_access_enabled = var.public_network_access_enabled
  https_only                    = var.https_only
  enabled                       = var.enabled
  functions_extension_version   = var.functions_extension_version
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
    always_on                              = try(var.site_config.always_on, null)
    api_definition_url                     = try(var.site_config.api_definition_url, null)
    app_command_line                       = try(var.site_config.app_command_line, null)
    application_insights_connection_string = try(var.site_config.application_insights_connection_string, null)
    application_insights_key               = try(var.site_config.application_insights_key, null)
    ftps_state                             = try(var.site_config.ftps_state, null)
    health_check_path                      = try(var.site_config.health_check_path, null)
    http2_enabled                          = try(var.site_config.http2_enabled, null)
    minimum_tls_version                    = try(var.site_config.minimum_tls_version, null)
    scm_minimum_tls_version                = try(var.site_config.scm_minimum_tls_version, null)
    use_32_bit_worker                      = try(var.site_config.use_32_bit_worker, null)
    websockets_enabled                     = try(var.site_config.websockets_enabled, null)
    vnet_route_all_enabled                 = try(var.site_config.vnet_route_all_enabled, null)

    dynamic "application_stack" {
      for_each = try(var.site_config.application_stack, null) == null ? [] : [var.site_config.application_stack]
      content {
        dotnet_version              = try(application_stack.value.dotnet_version, null)
        java_version                = try(application_stack.value.java_version, null)
        node_version                = try(application_stack.value.node_version, null)
        powershell_core_version     = try(application_stack.value.powershell_core_version, null)
        use_dotnet_isolated_runtime = try(application_stack.value.use_dotnet_isolated_runtime, null)
        use_custom_runtime          = try(application_stack.value.use_custom_runtime, null)
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

resource "azurerm_linux_function_app_slot" "this" {
  count = local.is_linux ? 1 : 0

  name                          = var.name
  function_app_id               = var.function_app_id
  storage_account_name          = try(var.storage.account_name, null)
  storage_account_access_key    = try(var.storage.account_access_key, null)
  storage_uses_managed_identity = try(var.storage.uses_managed_identity, null)
  storage_key_vault_secret_id   = try(var.storage.key_vault_secret_id, null)
  public_network_access_enabled = var.public_network_access_enabled
  https_only                    = var.https_only
  enabled                       = var.enabled
  functions_extension_version   = var.functions_extension_version
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
    always_on                              = try(var.site_config.always_on, null)
    api_definition_url                     = try(var.site_config.api_definition_url, null)
    app_command_line                       = try(var.site_config.app_command_line, null)
    application_insights_connection_string = try(var.site_config.application_insights_connection_string, null)
    application_insights_key               = try(var.site_config.application_insights_key, null)
    ftps_state                             = try(var.site_config.ftps_state, null)
    health_check_path                      = try(var.site_config.health_check_path, null)
    http2_enabled                          = try(var.site_config.http2_enabled, null)
    minimum_tls_version                    = try(var.site_config.minimum_tls_version, null)
    scm_minimum_tls_version                = try(var.site_config.scm_minimum_tls_version, null)
    use_32_bit_worker                      = try(var.site_config.use_32_bit_worker, null)
    websockets_enabled                     = try(var.site_config.websockets_enabled, null)
    vnet_route_all_enabled                 = try(var.site_config.vnet_route_all_enabled, null)

    dynamic "application_stack" {
      for_each = try(var.site_config.application_stack, null) == null ? [] : [var.site_config.application_stack]
      content {
        dotnet_version              = try(application_stack.value.dotnet_version, null)
        java_version                = try(application_stack.value.java_version, null)
        node_version                = try(application_stack.value.node_version, null)
        powershell_core_version     = try(application_stack.value.powershell_core_version, null)
        python_version              = try(application_stack.value.python_version, null)
        use_dotnet_isolated_runtime = try(application_stack.value.use_dotnet_isolated_runtime, null)
        use_custom_runtime          = try(application_stack.value.use_custom_runtime, null)
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
