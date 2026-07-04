locals {
  is_windows = lower(var.os_type) == "windows"
  is_linux   = lower(var.os_type) == "linux"
  empty_site_config = {
    always_on                              = null
    api_definition_url                     = null
    app_command_line                       = null
    application_insights_connection_string = null
    application_insights_key               = null
    ftps_state                             = null
    health_check_eviction_time_in_min      = null
    health_check_path                      = null
    http2_enabled                          = null
    minimum_tls_version                    = null
    scm_minimum_tls_version                = null
    use_32_bit_worker                      = null
    websockets_enabled                     = null
    vnet_route_all_enabled                 = null
    application_stack                      = null
  }
  site_config_defaults = {
    ftps_state              = "Disabled"
    http2_enabled           = true
    minimum_tls_version     = "1.2"
    scm_minimum_tls_version = "1.2"
  }
  effective_site_config = coalesce(var.site_config, local.empty_site_config)
}

resource "azurerm_windows_function_app" "this" {
  count = local.is_windows ? 1 : 0

  name                                           = var.name
  resource_group_name                            = var.resource_group_name
  location                                       = var.location
  service_plan_id                                = var.service_plan_id
  storage_account_name                           = var.storage.account_name
  storage_account_access_key                     = try(var.storage.account_access_key, null)
  storage_uses_managed_identity                  = try(var.storage.uses_managed_identity, false)
  storage_key_vault_secret_id                    = try(var.storage.key_vault_secret_id, null)
  public_network_access_enabled                  = var.public_network_access_enabled
  https_only                                     = var.https_only
  functions_extension_version                    = var.functions_extension_version
  enabled                                        = var.enabled
  builtin_logging_enabled                        = var.builtin_logging_enabled
  client_certificate_enabled                     = var.client_certificate_enabled
  client_certificate_mode                        = var.client_certificate_mode
  key_vault_reference_identity_id                = var.key_vault_reference_identity_id
  virtual_network_backup_restore_enabled         = var.virtual_network_backup_restore_enabled
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

  dynamic "site_config" {
    for_each = [local.effective_site_config]
    content {
      always_on                              = try(site_config.value.always_on, null)
      api_definition_url                     = try(site_config.value.api_definition_url, null)
      app_command_line                       = try(site_config.value.app_command_line, null)
      application_insights_connection_string = try(site_config.value.application_insights_connection_string, null)
      application_insights_key               = try(site_config.value.application_insights_key, null)
      ftps_state                             = coalesce(try(site_config.value.ftps_state, null), local.site_config_defaults.ftps_state)
      health_check_eviction_time_in_min      = try(site_config.value.health_check_eviction_time_in_min, null)
      health_check_path                      = try(site_config.value.health_check_path, null)
      http2_enabled                          = coalesce(try(site_config.value.http2_enabled, null), local.site_config_defaults.http2_enabled)
      minimum_tls_version                    = coalesce(try(site_config.value.minimum_tls_version, null), local.site_config_defaults.minimum_tls_version)
      scm_minimum_tls_version                = coalesce(try(site_config.value.scm_minimum_tls_version, null), local.site_config_defaults.scm_minimum_tls_version)
      use_32_bit_worker                      = try(site_config.value.use_32_bit_worker, null)
      websockets_enabled                     = try(site_config.value.websockets_enabled, null)
      vnet_route_all_enabled                 = try(site_config.value.vnet_route_all_enabled, null)

      dynamic "application_stack" {
        for_each = try(site_config.value.application_stack, null) == null ? [] : [site_config.value.application_stack]
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
  }

  dynamic "connection_string" {
    for_each = var.connection_strings
    content {
      name  = connection_string.key
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  dynamic "backup" {
    for_each = var.backup == null ? [] : [var.backup]
    content {
      name                = backup.value.name
      storage_account_url = backup.value.storage_account_url
      enabled             = try(backup.value.enabled, true)

      schedule {
        frequency_interval       = backup.value.schedule.frequency_interval
        frequency_unit           = backup.value.schedule.frequency_unit
        keep_at_least_one_backup = try(backup.value.schedule.keep_at_least_one_backup, true)
        retention_period_days    = try(backup.value.schedule.retention_period_days, null)
        start_time               = try(backup.value.schedule.start_time, null)
      }
    }
  }

  dynamic "sticky_settings" {
    for_each = var.sticky_settings == null ? [] : [var.sticky_settings]
    content {
      app_setting_names       = try(sticky_settings.value.app_setting_names, [])
      connection_string_names = try(sticky_settings.value.connection_string_names, [])
    }
  }

  dynamic "auth_settings_v2" {
    for_each = var.auth_settings_v2 == null ? [] : [var.auth_settings_v2]
    content {
      auth_enabled                            = try(auth_settings_v2.value.auth_enabled, null)
      config_file_path                        = try(auth_settings_v2.value.config_file_path, null)
      default_provider                        = try(auth_settings_v2.value.default_provider, null)
      excluded_paths                          = try(auth_settings_v2.value.excluded_paths, [])
      forward_proxy_convention                = try(auth_settings_v2.value.forward_proxy_convention, null)
      forward_proxy_custom_host_header_name   = try(auth_settings_v2.value.forward_proxy_custom_host_header_name, null)
      forward_proxy_custom_scheme_header_name = try(auth_settings_v2.value.forward_proxy_custom_scheme_header_name, null)
      http_route_api_prefix                   = try(auth_settings_v2.value.http_route_api_prefix, null)
      require_authentication                  = try(auth_settings_v2.value.require_authentication, null)
      require_https                           = coalesce(try(auth_settings_v2.value.require_https, null), true)
      runtime_version                         = try(auth_settings_v2.value.runtime_version, null)
      unauthenticated_action                  = try(auth_settings_v2.value.unauthenticated_action, null)

      dynamic "active_directory_v2" {
        for_each = try(auth_settings_v2.value.active_directory_v2, null) == null ? [] : [auth_settings_v2.value.active_directory_v2]
        content {
          client_id                            = active_directory_v2.value.client_id
          tenant_auth_endpoint                 = active_directory_v2.value.tenant_auth_endpoint
          allowed_applications                 = try(active_directory_v2.value.allowed_applications, [])
          allowed_audiences                    = try(active_directory_v2.value.allowed_audiences, [])
          allowed_groups                       = try(active_directory_v2.value.allowed_groups, [])
          allowed_identities                   = try(active_directory_v2.value.allowed_identities, [])
          client_secret_certificate_thumbprint = try(active_directory_v2.value.client_secret_certificate_thumbprint, null)
          client_secret_setting_name           = try(active_directory_v2.value.client_secret_setting_name, null)
          jwt_allowed_client_applications      = try(active_directory_v2.value.jwt_allowed_client_applications, [])
          jwt_allowed_groups                   = try(active_directory_v2.value.jwt_allowed_groups, [])
          login_parameters                     = try(active_directory_v2.value.login_parameters, {})
          www_authentication_disabled          = try(active_directory_v2.value.www_authentication_disabled, false)
        }
      }

      dynamic "apple_v2" {
        for_each = try(auth_settings_v2.value.apple_v2, null) == null ? [] : [auth_settings_v2.value.apple_v2]
        content {
          client_id                  = apple_v2.value.client_id
          client_secret_setting_name = apple_v2.value.client_secret_setting_name
        }
      }

      dynamic "azure_static_web_app_v2" {
        for_each = try(auth_settings_v2.value.azure_static_web_app_v2, null) == null ? [] : [auth_settings_v2.value.azure_static_web_app_v2]
        content {
          client_id = azure_static_web_app_v2.value.client_id
        }
      }

      dynamic "custom_oidc_v2" {
        for_each = try(auth_settings_v2.value.custom_oidc_v2, {})
        content {
          name                          = custom_oidc_v2.key
          client_id                     = custom_oidc_v2.value.client_id
          openid_configuration_endpoint = custom_oidc_v2.value.openid_configuration_endpoint
          name_claim_type               = try(custom_oidc_v2.value.name_claim_type, null)
          scopes                        = try(custom_oidc_v2.value.scopes, [])
        }
      }

      dynamic "facebook_v2" {
        for_each = try(auth_settings_v2.value.facebook_v2, null) == null ? [] : [auth_settings_v2.value.facebook_v2]
        content {
          app_id                  = facebook_v2.value.app_id
          app_secret_setting_name = facebook_v2.value.app_secret_setting_name
          graph_api_version       = try(facebook_v2.value.graph_api_version, null)
          login_scopes            = try(facebook_v2.value.login_scopes, [])
        }
      }

      dynamic "github_v2" {
        for_each = try(auth_settings_v2.value.github_v2, null) == null ? [] : [auth_settings_v2.value.github_v2]
        content {
          client_id                  = github_v2.value.client_id
          client_secret_setting_name = github_v2.value.client_secret_setting_name
          login_scopes               = try(github_v2.value.login_scopes, [])
        }
      }

      dynamic "google_v2" {
        for_each = try(auth_settings_v2.value.google_v2, null) == null ? [] : [auth_settings_v2.value.google_v2]
        content {
          client_id                  = google_v2.value.client_id
          client_secret_setting_name = google_v2.value.client_secret_setting_name
          allowed_audiences          = try(google_v2.value.allowed_audiences, [])
          login_scopes               = try(google_v2.value.login_scopes, [])
        }
      }

      dynamic "login" {
        for_each = try(auth_settings_v2.value.login, null) == null ? [] : [auth_settings_v2.value.login]
        content {
          allowed_external_redirect_urls    = try(login.value.allowed_external_redirect_urls, [])
          cookie_expiration_convention      = try(login.value.cookie_expiration_convention, null)
          cookie_expiration_time            = try(login.value.cookie_expiration_time, null)
          logout_endpoint                   = try(login.value.logout_endpoint, null)
          nonce_expiration_time             = try(login.value.nonce_expiration_time, null)
          preserve_url_fragments_for_logins = try(login.value.preserve_url_fragments_for_logins, null)
          token_refresh_extension_time      = try(login.value.token_refresh_extension_time, null)
          token_store_enabled               = try(login.value.token_store_enabled, null)
          token_store_path                  = try(login.value.token_store_path, null)
          token_store_sas_setting_name      = try(login.value.token_store_sas_setting_name, null)
          validate_nonce                    = try(login.value.validate_nonce, null)
        }
      }

      dynamic "microsoft_v2" {
        for_each = try(auth_settings_v2.value.microsoft_v2, null) == null ? [] : [auth_settings_v2.value.microsoft_v2]
        content {
          client_id                  = microsoft_v2.value.client_id
          client_secret_setting_name = microsoft_v2.value.client_secret_setting_name
          allowed_audiences          = try(microsoft_v2.value.allowed_audiences, [])
          login_scopes               = try(microsoft_v2.value.login_scopes, [])
        }
      }

      dynamic "twitter_v2" {
        for_each = try(auth_settings_v2.value.twitter_v2, null) == null ? [] : [auth_settings_v2.value.twitter_v2]
        content {
          consumer_key                 = twitter_v2.value.consumer_key
          consumer_secret_setting_name = twitter_v2.value.consumer_secret_setting_name
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition = (
        (try(var.storage.key_vault_secret_id, null) != null) !=
        (try(var.storage.account_name, null) != null)
      )
      error_message = "Set exactly one of storage.key_vault_secret_id or storage.account_name."
    }
    precondition {
      condition = (
        try(var.storage.account_name, null) == null ||
        (
          try(var.storage.account_access_key, null) != null ||
          try(var.storage.uses_managed_identity, false)
        )
      )
      error_message = "When storage.account_name is set, also set storage.account_access_key or storage.uses_managed_identity=true."
    }
    precondition {
      condition = !(
        try(var.storage.account_access_key, null) != null &&
        try(var.storage.uses_managed_identity, false)
      )
      error_message = "storage.account_access_key conflicts with storage.uses_managed_identity=true."
    }
  }
}

resource "azurerm_linux_function_app" "this" {
  count = local.is_linux ? 1 : 0

  name                                           = var.name
  resource_group_name                            = var.resource_group_name
  location                                       = var.location
  service_plan_id                                = var.service_plan_id
  storage_account_name                           = var.storage.account_name
  storage_account_access_key                     = try(var.storage.account_access_key, null)
  storage_uses_managed_identity                  = try(var.storage.uses_managed_identity, false)
  storage_key_vault_secret_id                    = try(var.storage.key_vault_secret_id, null)
  public_network_access_enabled                  = var.public_network_access_enabled
  https_only                                     = var.https_only
  functions_extension_version                    = var.functions_extension_version
  enabled                                        = var.enabled
  builtin_logging_enabled                        = var.builtin_logging_enabled
  client_certificate_enabled                     = var.client_certificate_enabled
  client_certificate_mode                        = var.client_certificate_mode
  key_vault_reference_identity_id                = var.key_vault_reference_identity_id
  virtual_network_backup_restore_enabled         = var.virtual_network_backup_restore_enabled
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

  dynamic "site_config" {
    for_each = [local.effective_site_config]
    content {
      always_on                              = try(site_config.value.always_on, null)
      api_definition_url                     = try(site_config.value.api_definition_url, null)
      app_command_line                       = try(site_config.value.app_command_line, null)
      application_insights_connection_string = try(site_config.value.application_insights_connection_string, null)
      application_insights_key               = try(site_config.value.application_insights_key, null)
      ftps_state                             = coalesce(try(site_config.value.ftps_state, null), local.site_config_defaults.ftps_state)
      health_check_eviction_time_in_min      = try(site_config.value.health_check_eviction_time_in_min, null)
      health_check_path                      = try(site_config.value.health_check_path, null)
      http2_enabled                          = coalesce(try(site_config.value.http2_enabled, null), local.site_config_defaults.http2_enabled)
      minimum_tls_version                    = coalesce(try(site_config.value.minimum_tls_version, null), local.site_config_defaults.minimum_tls_version)
      scm_minimum_tls_version                = coalesce(try(site_config.value.scm_minimum_tls_version, null), local.site_config_defaults.scm_minimum_tls_version)
      use_32_bit_worker                      = try(site_config.value.use_32_bit_worker, null)
      websockets_enabled                     = try(site_config.value.websockets_enabled, null)
      vnet_route_all_enabled                 = try(site_config.value.vnet_route_all_enabled, null)

      dynamic "application_stack" {
        for_each = try(site_config.value.application_stack, null) == null ? [] : [site_config.value.application_stack]
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
  }

  dynamic "connection_string" {
    for_each = var.connection_strings
    content {
      name  = connection_string.key
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  dynamic "backup" {
    for_each = var.backup == null ? [] : [var.backup]
    content {
      name                = backup.value.name
      storage_account_url = backup.value.storage_account_url
      enabled             = try(backup.value.enabled, true)

      schedule {
        frequency_interval       = backup.value.schedule.frequency_interval
        frequency_unit           = backup.value.schedule.frequency_unit
        keep_at_least_one_backup = try(backup.value.schedule.keep_at_least_one_backup, true)
        retention_period_days    = try(backup.value.schedule.retention_period_days, null)
        start_time               = try(backup.value.schedule.start_time, null)
      }
    }
  }

  dynamic "sticky_settings" {
    for_each = var.sticky_settings == null ? [] : [var.sticky_settings]
    content {
      app_setting_names       = try(sticky_settings.value.app_setting_names, [])
      connection_string_names = try(sticky_settings.value.connection_string_names, [])
    }
  }

  dynamic "auth_settings_v2" {
    for_each = var.auth_settings_v2 == null ? [] : [var.auth_settings_v2]
    content {
      auth_enabled                            = try(auth_settings_v2.value.auth_enabled, null)
      config_file_path                        = try(auth_settings_v2.value.config_file_path, null)
      default_provider                        = try(auth_settings_v2.value.default_provider, null)
      excluded_paths                          = try(auth_settings_v2.value.excluded_paths, [])
      forward_proxy_convention                = try(auth_settings_v2.value.forward_proxy_convention, null)
      forward_proxy_custom_host_header_name   = try(auth_settings_v2.value.forward_proxy_custom_host_header_name, null)
      forward_proxy_custom_scheme_header_name = try(auth_settings_v2.value.forward_proxy_custom_scheme_header_name, null)
      http_route_api_prefix                   = try(auth_settings_v2.value.http_route_api_prefix, null)
      require_authentication                  = try(auth_settings_v2.value.require_authentication, null)
      require_https                           = coalesce(try(auth_settings_v2.value.require_https, null), true)
      runtime_version                         = try(auth_settings_v2.value.runtime_version, null)
      unauthenticated_action                  = try(auth_settings_v2.value.unauthenticated_action, null)

      dynamic "active_directory_v2" {
        for_each = try(auth_settings_v2.value.active_directory_v2, null) == null ? [] : [auth_settings_v2.value.active_directory_v2]
        content {
          client_id                            = active_directory_v2.value.client_id
          tenant_auth_endpoint                 = active_directory_v2.value.tenant_auth_endpoint
          allowed_applications                 = try(active_directory_v2.value.allowed_applications, [])
          allowed_audiences                    = try(active_directory_v2.value.allowed_audiences, [])
          allowed_groups                       = try(active_directory_v2.value.allowed_groups, [])
          allowed_identities                   = try(active_directory_v2.value.allowed_identities, [])
          client_secret_certificate_thumbprint = try(active_directory_v2.value.client_secret_certificate_thumbprint, null)
          client_secret_setting_name           = try(active_directory_v2.value.client_secret_setting_name, null)
          jwt_allowed_client_applications      = try(active_directory_v2.value.jwt_allowed_client_applications, [])
          jwt_allowed_groups                   = try(active_directory_v2.value.jwt_allowed_groups, [])
          login_parameters                     = try(active_directory_v2.value.login_parameters, {})
          www_authentication_disabled          = try(active_directory_v2.value.www_authentication_disabled, false)
        }
      }

      dynamic "apple_v2" {
        for_each = try(auth_settings_v2.value.apple_v2, null) == null ? [] : [auth_settings_v2.value.apple_v2]
        content {
          client_id                  = apple_v2.value.client_id
          client_secret_setting_name = apple_v2.value.client_secret_setting_name
        }
      }

      dynamic "azure_static_web_app_v2" {
        for_each = try(auth_settings_v2.value.azure_static_web_app_v2, null) == null ? [] : [auth_settings_v2.value.azure_static_web_app_v2]
        content {
          client_id = azure_static_web_app_v2.value.client_id
        }
      }

      dynamic "custom_oidc_v2" {
        for_each = try(auth_settings_v2.value.custom_oidc_v2, {})
        content {
          name                          = custom_oidc_v2.key
          client_id                     = custom_oidc_v2.value.client_id
          openid_configuration_endpoint = custom_oidc_v2.value.openid_configuration_endpoint
          name_claim_type               = try(custom_oidc_v2.value.name_claim_type, null)
          scopes                        = try(custom_oidc_v2.value.scopes, [])
        }
      }

      dynamic "facebook_v2" {
        for_each = try(auth_settings_v2.value.facebook_v2, null) == null ? [] : [auth_settings_v2.value.facebook_v2]
        content {
          app_id                  = facebook_v2.value.app_id
          app_secret_setting_name = facebook_v2.value.app_secret_setting_name
          graph_api_version       = try(facebook_v2.value.graph_api_version, null)
          login_scopes            = try(facebook_v2.value.login_scopes, [])
        }
      }

      dynamic "github_v2" {
        for_each = try(auth_settings_v2.value.github_v2, null) == null ? [] : [auth_settings_v2.value.github_v2]
        content {
          client_id                  = github_v2.value.client_id
          client_secret_setting_name = github_v2.value.client_secret_setting_name
          login_scopes               = try(github_v2.value.login_scopes, [])
        }
      }

      dynamic "google_v2" {
        for_each = try(auth_settings_v2.value.google_v2, null) == null ? [] : [auth_settings_v2.value.google_v2]
        content {
          client_id                  = google_v2.value.client_id
          client_secret_setting_name = google_v2.value.client_secret_setting_name
          allowed_audiences          = try(google_v2.value.allowed_audiences, [])
          login_scopes               = try(google_v2.value.login_scopes, [])
        }
      }

      dynamic "login" {
        for_each = try(auth_settings_v2.value.login, null) == null ? [] : [auth_settings_v2.value.login]
        content {
          allowed_external_redirect_urls    = try(login.value.allowed_external_redirect_urls, [])
          cookie_expiration_convention      = try(login.value.cookie_expiration_convention, null)
          cookie_expiration_time            = try(login.value.cookie_expiration_time, null)
          logout_endpoint                   = try(login.value.logout_endpoint, null)
          nonce_expiration_time             = try(login.value.nonce_expiration_time, null)
          preserve_url_fragments_for_logins = try(login.value.preserve_url_fragments_for_logins, null)
          token_refresh_extension_time      = try(login.value.token_refresh_extension_time, null)
          token_store_enabled               = try(login.value.token_store_enabled, null)
          token_store_path                  = try(login.value.token_store_path, null)
          token_store_sas_setting_name      = try(login.value.token_store_sas_setting_name, null)
          validate_nonce                    = try(login.value.validate_nonce, null)
        }
      }

      dynamic "microsoft_v2" {
        for_each = try(auth_settings_v2.value.microsoft_v2, null) == null ? [] : [auth_settings_v2.value.microsoft_v2]
        content {
          client_id                  = microsoft_v2.value.client_id
          client_secret_setting_name = microsoft_v2.value.client_secret_setting_name
          allowed_audiences          = try(microsoft_v2.value.allowed_audiences, [])
          login_scopes               = try(microsoft_v2.value.login_scopes, [])
        }
      }

      dynamic "twitter_v2" {
        for_each = try(auth_settings_v2.value.twitter_v2, null) == null ? [] : [auth_settings_v2.value.twitter_v2]
        content {
          consumer_key                 = twitter_v2.value.consumer_key
          consumer_secret_setting_name = twitter_v2.value.consumer_secret_setting_name
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition = (
        (try(var.storage.key_vault_secret_id, null) != null) !=
        (try(var.storage.account_name, null) != null)
      )
      error_message = "Set exactly one of storage.key_vault_secret_id or storage.account_name."
    }
    precondition {
      condition = (
        try(var.storage.account_name, null) == null ||
        (
          try(var.storage.account_access_key, null) != null ||
          try(var.storage.uses_managed_identity, false)
        )
      )
      error_message = "When storage.account_name is set, also set storage.account_access_key or storage.uses_managed_identity=true."
    }
    precondition {
      condition = !(
        try(var.storage.account_access_key, null) != null &&
        try(var.storage.uses_managed_identity, false)
      )
      error_message = "storage.account_access_key conflicts with storage.uses_managed_identity=true."
    }
  }
}
