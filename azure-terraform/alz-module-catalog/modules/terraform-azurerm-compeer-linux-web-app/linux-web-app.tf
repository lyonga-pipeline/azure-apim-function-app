resource "azurerm_linux_web_app" "linux_web_app" {
  location            = var.location
  name                = var.name
  resource_group_name = var.resource_group_name
  service_plan_id     = var.service_plan_id

  app_settings                       = var.app_settings
  client_affinity_enabled            = var.client_affinity_enabled
  client_certificate_enabled         = var.client_certificate_enabled
  client_certificate_mode            = var.client_certificate_mode
  client_certificate_exclusion_paths = var.client_certificate_exclusion_paths
  enabled                            = var.enabled
  https_only                         = var.https_only
  public_network_access_enabled      = var.public_network_access_enabled
  key_vault_reference_identity_id    = var.key_vault_reference_identity_id
  virtual_network_subnet_id          = var.virtual_network_subnet_id
  zip_deploy_file                    = var.zip_deploy_file
  tags                               = var.tags
  dynamic "site_config" {
    for_each = var.site_config
    content {
      always_on                                     = lookup(site_config.value, "always_on", null)
      api_definition_url                            = lookup(site_config.value, "api_definition_url", null)
      api_management_api_id                         = lookup(site_config.value, "api_management_api_id", null)
      app_command_line                              = lookup(site_config.value, "app_command_line", null)
      container_registry_managed_identity_client_id = lookup(site_config.value, "container_registry_managed_identity_client_id", null)
      container_registry_use_managed_identity       = lookup(site_config.value, "container_registry_use_managed_identity", null)
      default_documents                             = lookup(site_config.value, "default_documents", null)
      ftps_state                                    = lookup(site_config.value, "ftps_state", null)
      health_check_path                             = lookup(site_config.value, "health_check_path", null)
      health_check_eviction_time_in_min             = lookup(site_config.value, "health_check_eviction_time_in_min", null)
      http2_enabled                                 = lookup(site_config.value, "http2_enabled", null)
      load_balancing_mode                           = lookup(site_config.value, "load_balancing_mode", null)
      local_mysql_enabled                           = lookup(site_config.value, "local_mysql_enabled", null)
      managed_pipeline_mode                         = lookup(site_config.value, "managed_pipeline_mode", null)
      minimum_tls_version                           = lookup(site_config.value, "minimum_tls_version", null)
      remote_debugging_enabled                      = lookup(site_config.value, "remote_debugging_enabled", null)
      remote_debugging_version                      = lookup(site_config.value, "remote_debugging_version", null)
      scm_minimum_tls_version                       = lookup(site_config.value, "scm_minimum_tls_version", null)
      scm_use_main_ip_restriction                   = lookup(site_config.value, "scm_use_main_ip_restriction", null)
      use_32_bit_worker                             = lookup(site_config.value, "use_32_bit_worker", null)
      vnet_route_all_enabled                        = lookup(site_config.value, "vnet_route_all_enabled", null)
      websockets_enabled                            = lookup(site_config.value, "websockets_enabled", null)
      worker_count                                  = lookup(site_config.value, "worker_count", null)
      dynamic "application_stack" {
        for_each = lookup(site_config.value, "application_stack", null)
        content {
          docker_image_name        = lookup(application_stack.value, "docker_image_name", null)
          docker_registry_url      = lookup(application_stack.value, "docker_registry_url", null)
          docker_registry_username = lookup(application_stack.value, "docker_registry_username", null)
          docker_registry_password = lookup(application_stack.value, "docker_registry_password", null)
          go_version               = lookup(application_stack.value, "go_version", null)
          java_server              = lookup(application_stack.value, "java_server", null)
          java_server_version      = lookup(application_stack.value, "java_server_version", null)
          java_version             = lookup(application_stack.value, "java_version", null)
          node_version             = lookup(application_stack.value, "node_version", null)
          php_version              = lookup(application_stack.value, "php_version", null)
          python_version           = lookup(application_stack.value, "python_version", null)
          ruby_version             = lookup(application_stack.value, "ruby_version", null)
        }
      }
      dynamic "auto_heal_setting" {
        for_each = lookup(site_config.value, "auto_heal_setting", null)
        content {
          dynamic "action" {
            for_each = lookup(site_config.value.auto_heal_setting.value, "action", null)
            content {
              action_type                    = lookup(action.value, "action_type", null)
              minimum_process_execution_time = lookup(action.value, "minimum_process_execution_time", null)
            }
          }
          dynamic "trigger" {
            for_each = lookup(site_config.value.auto_heal_setting.value, "trigger", null)
            content {
              dynamic "requests" {
                for_each = lookup(site_config.value.auto_heal_setting.value.trigger.value, "requests", null)
                content {
                  count    = lookup(requests.value, "count", null)
                  interval = lookup(requests.value, "interval", null)
                }
              }
              dynamic "slow_request" {
                for_each = lookup(site_config.value.auto_heal_setting.value.trigger.value, "slow_request", null)
                content {
                  count      = lookup(slow_request.value, "count", null)
                  interval   = lookup(slow_request.value, "interval", null)
                  time_taken = lookup(slow_request.value, "time_taken", null)
                }
              }
              dynamic "status_code" {
                for_each = lookup(site_config.value.auto_heal_setting.value.trigger.value, "status_code", null)
                content {
                  count             = lookup(status_code.value, "count", null)
                  interval          = lookup(status_code.value, "interval", null)
                  status_code_range = lookup(status_code.value, "status_code_range", null)
                  path              = lookup(status_code.value, "path", null)
                  sub_status        = lookup(status_code.value, "sub_status", null)
                  win32_status_code = lookup(status_code.value, "win32_status_code", null)
                }
              }
            }
          }
        }
      }
      dynamic "cors" {
        for_each = lookup(site_config.value, "cors", [])
        content {
          allowed_origins     = cors.value.allowed_origins
          support_credentials = lookup(cors.value, "support_credentials", false)
        }
      }
      dynamic "ip_restriction" {
        for_each = lookup(site_config.value, "ip_restriction", [])
        content {
          action                    = ip_restriction.value.action
          ip_address                = ip_restriction.value.ip_address
          name                      = ip_restriction.value.name
          priority                  = ip_restriction.value.priority
          service_tag               = ip_restriction.value.service_tag
          virtual_network_subnet_id = ip_restriction.value.virtual_network_subnet_id
          dynamic "headers" {
            for_each = ip_restriction.value.headers ? [ip_restriction.value.headers] : []
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
        for_each = lookup(site_config.value, "scm_ip_restriction", [])
        content {
          action                    = scm_ip_restriction.value.action
          ip_address                = scm_ip_restriction.value.ip_address
          name                      = scm_ip_restriction.value.name
          priority                  = scm_ip_restriction.value.priority
          service_tag               = scm_ip_restriction.value.service_tag
          virtual_network_subnet_id = scm_ip_restriction.value.virtual_network_subnet_id
          dynamic "headers" {
            for_each = scm_ip_restriction.value.headers ? [scm_ip_restriction.value.headers] : []
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
  dynamic "auth_settings" {
    for_each = var.auth_settings != null ? [var.auth_settings] : []
    content {
      enabled                        = auth_settings.value.enabled
      additional_login_parameters    = lookup(auth_settings.value, "additional_login_parameters", null)
      allowed_external_redirect_urls = lookup(auth_settings.value, "allowed_external_redirect_urls", null)
      runtime_version                = lookup(auth_settings.value, "runtime_version", null)
      token_refresh_extension_hours  = lookup(auth_settings.value, "token_refresh_extension_hours", null)
      token_store_enabled            = lookup(auth_settings.value, "token_store_enabled", false)
      unauthenticated_client_action  = lookup(auth_settings.value, "unauthenticated_client_action", "RedirectToLoginPage")
      dynamic "active_directory" {
        for_each = lookup(auth_settings.value, "active_directory", null)
        content {
          client_id                  = active_directory.value.client_id
          allowed_audiences          = lookup(active_directory.value, "allowed_audiences", null)
          client_secret              = lookup(active_directory.value, "client_secret", null)
          client_secret_setting_name = lookup(active_directory.value, "client_secret_setting_name", null) # Cannot be used with client_secret.
        }
      }
      dynamic "microsoft" {
        for_each = lookup(auth_settings.value, "microsoft", null)
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
    for_each = var.backup != null ? [var.backup] : []
    content {
      name                = backup.value.name
      storage_account_url = backup.value.storage_account_url
      enabled             = backup.value.enabled
      dynamic "schedule" {
        for_each = lookup(backup.value, "schedule", null)
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
    for_each = var.connection_string != null ? [var.connection_string] : []
    content {
      name  = connection_string.value.name
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }
  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []
    content {
      type         = lookup(identity.value, "type", null)
      identity_ids = lookup(identity.value, "identity_ids", null)
    }
  }
  dynamic "logs" {
    for_each = var.logs != null ? [var.logs] : []
    content {
      detailed_error_messages = lookup(logs.value, "detailed_error_messages", null)
      failed_request_tracing  = lookup(logs.value, "failed_request_tracing", null)
      dynamic "application_logs" {
        for_each = lookup(logs.value, "application_logs", null)
        content {
          file_system_level = application_logs.value.file_system_level
          dynamic "azure_blob_storage" {
            for_each = lookup(logs.value.application_logs.value, "azure_blob_storage", null)
            content {
              level             = azure_blob_storage.value.level
              retention_in_days = azure_blob_storage.value.retention_in_days
              sas_url           = azure_blob_storage.value.sas_url
            }
          }
        }
      }
      dynamic "http_logs" {
        for_each = lookup(logs.value, "http_logs", null)
        content {
          dynamic "azure_blob_storage" {
            for_each = lookup(logs.value.http_logs.value, "azure_blob_storage", null)
            content {
              retention_in_days = azure_blob_storage.value.retention_in_days
              sas_url           = azure_blob_storage.value.sas_url
            }
          }
          dynamic "file_system" {
            for_each = lookup(logs.value.http_logs.value, "file_system", null)
            content {
              retention_in_days = file_system.value.retention_in_days
              retention_in_mb   = file_system.value.retention_in_mb
            }
          }
        }
      }
    }
  }
  dynamic "sticky_settings" {
    for_each = var.sticky_settings != null ? [var.sticky_settings] : []
    content {
      app_setting_names       = lookup(sticky_settings.value, "app_setting_names", null)
      connection_string_names = lookup(sticky_settings.value, "connection_string_names", null)
    }
  }
  dynamic "storage_account" {
    for_each = var.storage_account != null ? [var.storage_account] : []
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