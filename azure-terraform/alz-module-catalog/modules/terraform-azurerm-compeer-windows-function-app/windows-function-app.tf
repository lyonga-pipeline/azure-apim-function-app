resource "azurerm_windows_function_app" "windows_function_app" {
  location            = var.location
  name                = var.name
  resource_group_name = var.resource_group_name
  service_plan_id     = var.service_plan_id
  dynamic "site_config" {
    for_each = var.site_config
    content {
      always_on                              = lookup(site_config.value, "always_on", null)
      api_definition_url                     = lookup(site_config.value, "api_definition_url", null)
      api_management_api_id                  = lookup(site_config.value, "api_management_api_id", null)
      app_command_line                       = lookup(site_config.value, "app_command_line", null)
      app_scale_limit                        = lookup(site_config.value, "app_scale_limit", null)
      application_insights_connection_string = lookup(site_config.value, "application_insights_connection_string", null)
      application_insights_key               = lookup(site_config.value, "application_insights_key", null)
      default_documents                      = lookup(site_config.value, "default_documents", null)
      elastic_instance_minimum               = lookup(site_config.value, "elastic_instance_minimum", null)
      ftps_state                             = lookup(site_config.value, "ftps_state", null)
      health_check_path                      = lookup(site_config.value, "health_check_path", null)
      health_check_eviction_time_in_min      = lookup(site_config.value, "health_check_eviction_time_in_min", null)
      http2_enabled                          = lookup(site_config.value, "http2_enabled", null)
      load_balancing_mode                    = lookup(site_config.value, "load_balancing_mode", null)
      managed_pipeline_mode                  = lookup(site_config.value, "managed_pipeline_mode", null)
      minimum_tls_version                    = lookup(site_config.value, "minimum_tls_version", null)
      pre_warmed_instance_count              = lookup(site_config.value, "pre_warmed_instance_count", null)
      remote_debugging_enabled               = lookup(site_config.value, "remote_debugging_enabled", null)
      remote_debugging_version               = lookup(site_config.value, "remote_debugging_version", null)
      runtime_scale_monitoring_enabled       = lookup(site_config.value, "runtime_scale_monitoring_enabled", null)
      scm_minimum_tls_version                = lookup(site_config.value, "scm_minimum_tls_version", null)
      scm_use_main_ip_restriction            = lookup(site_config.value, "scm_use_main_ip_restriction", null)
      use_32_bit_worker                      = lookup(site_config.value, "use_32_bit_worker", null)
      vnet_route_all_enabled                 = lookup(site_config.value, "vnet_route_all_enabled", null)
      websockets_enabled                     = lookup(site_config.value, "websockets_enabled", null)
      worker_count                           = lookup(site_config.value, "worker_count", null)
      dynamic "application_stack" {
        for_each = site_config.value.application_stack != null ? [site_config.value.application_stack] : []
        content {
          dotnet_version              = lookup(application_stack.value, "dotnet_version", null)
          use_dotnet_isolated_runtime = lookup(application_stack.value, "use_dotnet_isolated_runtime", null)
          java_version                = lookup(application_stack.value, "java_version", null)
          node_version                = lookup(application_stack.value, "node_version", null)
          powershell_core_version     = lookup(application_stack.value, "powershell_core_version", null)
          use_custom_runtime          = lookup(application_stack.value, "use_custom_runtime", null)
        }
      }
      dynamic "app_service_logs" {
        for_each = site_config.value.app_service_logs != null ? [site_config.value.app_service_logs] : []
        content {
          disk_quota_mb         = lookup(app_service_logs.value, "disk_quota_mb", null)
          retention_period_days = lookup(app_service_logs.value, "retention_period_days", null)
        }
      }
      dynamic "cors" {
        for_each = site_config.value.cors != null ? [site_config.value.cors] : []
        content {
          allowed_origins     = cors.value.allowed_origins
          support_credentials = lookup(cors.value, "support_credentials", false)
        }
      }
      dynamic "ip_restriction" {
        for_each = site_config.value.ip_restriction != null ? [site_config.value.ip_restriction] : []
        content {
          action                    = ip_restriction.value.action
          ip_address                = ip_restriction.value.ip_address
          name                      = ip_restriction.value.name
          priority                  = ip_restriction.value.priority
          service_tag               = ip_restriction.value.service_tag
          virtual_network_subnet_id = ip_restriction.value.virtual_network_subnet_id
          dynamic "headers" {
            for_each = ip_restriction.value.headers != null ? [ip_restriction.value.headers] : []
            content {
              x_azure_fdid      = headers.value.x_azure_fdid
              x_fd_health_probe = headers.value.x_fd_health_probe
              x_forwarded_for   = headers.value.x_forwarded_for
              x_forwarded_host  = headers.value.x_forwarded_host
            }
          }
        }
      }
      dynamic "scm_ip_restriction" {
        for_each = site_config.value.scm_ip_restriction != null ? [site_config.value.scm_ip_restriction] : []
        content {
          action                    = scm_ip_restriction.value.action
          ip_address                = scm_ip_restriction.value.ip_address
          name                      = scm_ip_restriction.value.name
          priority                  = scm_ip_restriction.value.priority
          service_tag               = scm_ip_restriction.value.service_tag
          virtual_network_subnet_id = scm_ip_restriction.value.virtual_network_subnet_id
          dynamic "headers" {
            for_each = scm_ip_restriction.value.headers != null ? [scm_ip_restriction.value.headers] : []
            content {
              x_azure_fdid      = headers.value.x_azure_fdid
              x_fd_health_probe = headers.value.x_fd_health_probe
              x_forwarded_for   = headers.value.x_forwarded_for
              x_forwarded_host  = headers.value.x_forwarded_host
            }
          }
        }
      }
    }
  }

  app_settings                                   = var.app_settings
  builtin_logging_enabled                        = var.builtin_logging_enabled
  client_certificate_enabled                     = var.client_certificate_enabled
  client_certificate_mode                        = var.client_certificate_mode
  client_certificate_exclusion_paths             = var.client_certificate_exclusion_paths
  content_share_force_disabled                   = var.content_share_force_disabled
  daily_memory_time_quota                        = var.daily_memory_time_quota
  enabled                                        = var.enabled
  ftp_publish_basic_authentication_enabled       = var.ftp_publish_basic_authentication_enabled
  functions_extension_version                    = var.functions_extension_version
  https_only                                     = var.https_only
  key_vault_reference_identity_id                = var.key_vault_reference_identity_id
  public_network_access_enabled                  = var.public_network_access_enabled
  storage_account_name                           = var.storage_account_name
  storage_key_vault_secret_id                    = var.storage_key_vault_secret_id
  storage_uses_managed_identity                  = var.storage_uses_managed_identity
  storage_account_access_key                     = var.storage_account_access_key
  virtual_network_subnet_id                      = var.virtual_network_subnet_id
  webdeploy_publish_basic_authentication_enabled = var.webdeploy_publish_basic_authentication_enabled
  zip_deploy_file                                = var.zip_deploy_file
  tags                                           = var.tags
  dynamic "auth_settings" {
    for_each = var.auth_settings
    content {
      enabled                        = auth_settings.value.enabled
      additional_login_parameters    = lookup(auth_settings.value, "additional_login_parameters", null)
      allowed_external_redirect_urls = lookup(auth_settings.value, "allowed_external_redirect_urls", null)
      runtime_version                = lookup(auth_settings.value, "runtime_version", null)
      token_refresh_extension_hours  = lookup(auth_settings.value, "token_refresh_extension_hours", null)
      token_store_enabled            = lookup(auth_settings.value, "token_store_enabled", false)
      unauthenticated_client_action  = lookup(auth_settings.value, "unauthenticated_client_action", "RedirectToLoginPage")
      dynamic "active_directory" {
        for_each = auth_settings.value.active_directory != null ? [auth_settings.value.active_directory] : []
        content {
          client_id                  = active_directory.value.client_id
          allowed_audiences          = lookup(active_directory.value, "allowed_audiences", null)
          client_secret              = lookup(active_directory.value, "client_secret", null)
          client_secret_setting_name = lookup(active_directory.value, "client_secret_setting_name", null) # Cannot be used with client_secret.
        }
      }
      dynamic "microsoft" {
        for_each = auth_settings.value.microsoft != null ? [auth_settings.value.microsoft] : []
        content {
          client_id                  = microsoft.value.client_id
          client_secret              = lookup(microsoft.value, "client_secret", null)
          client_secret_setting_name = lookup(microsoft.value, "client_secret_setting_name", null)
          oauth_scopes               = lookup(microsoft.value, "oauth_scopes", null)
        }
      }
    }
  }
  dynamic "backup" {
    for_each = var.backup
    content {
      name                = backup.value.name
      storage_account_url = backup.value.storage_account_url
      enabled             = backup.value.enabled
      dynamic "schedule" {
        for_each = backup.value.schedule != null ? [backup.value.schedule] : []
        content {
          frequency_interval       = schedule.value.frequency_interval
          frequency_unit           = schedule.value.frequency_unit
          keep_at_least_one_backup = lookup(schedule.value, "keep_at_least_one_backup", null)
          retention_period_days    = lookup(schedule.value, "retention_period_days", null)
          start_time               = lookup(schedule.value, "start_time", null)
        }
      }
    }
  }
  dynamic "connection_string" {
    for_each = var.connection_string
    content {
      name  = connection_string.key
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }
  dynamic "identity" {
    for_each = var.identity
    content {
      type         = lookup(identity.value, "type", null)
      identity_ids = lookup(identity.value, "identity_ids", null)
    }
  }
  dynamic "sticky_settings" {
    for_each = var.sticky_settings
    content {
      app_setting_names       = lookup(sticky_settings.value, "app_setting_names", null)
      connection_string_names = lookup(sticky_settings.value, "connection_string_names", null)
    }
  }
  dynamic "storage_account" {
    for_each = var.storage_account
    content {
      access_key   = lookup(storage_account.value, "access_key", null)
      account_name = lookup(storage_account.value, "account_name", null)
      name         = lookup(storage_account.value, "name", null)
      share_name   = lookup(storage_account.value, "share_name", null)
      type         = lookup(storage_account.value, "type", null)
      mount_path   = lookup(storage_account.value, "mount_path", null)
    }
  }
}
