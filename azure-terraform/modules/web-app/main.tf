locals {
  is_windows = lower(var.os_type) == "windows"
  is_linux   = lower(var.os_type) == "linux"
}

resource "azurerm_windows_web_app" "this" {
  count = local.is_windows ? 1 : 0

  name                                           = var.name
  resource_group_name                            = var.resource_group_name
  location                                       = var.location
  service_plan_id                                = var.service_plan_id
  public_network_access_enabled                  = var.public_network_access_enabled
  https_only                                     = var.https_only
  enabled                                        = var.enabled
  client_affinity_enabled                        = var.client_affinity_enabled
  client_certificate_enabled                     = var.client_certificate_enabled
  client_certificate_mode                        = var.client_certificate_mode
  client_certificate_exclusion_paths             = var.client_certificate_exclusion_paths
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
    for_each = var.site_config == null ? [] : [var.site_config]
    content {
      always_on               = try(site_config.value.always_on, null)
      ftps_state              = try(site_config.value.ftps_state, null)
      health_check_path       = try(site_config.value.health_check_path, null)
      http2_enabled           = try(site_config.value.http2_enabled, null)
      minimum_tls_version     = try(site_config.value.minimum_tls_version, null)
      scm_minimum_tls_version = try(site_config.value.scm_minimum_tls_version, null)
      use_32_bit_worker       = try(site_config.value.use_32_bit_worker, null)
      websockets_enabled      = try(site_config.value.websockets_enabled, null)
      vnet_route_all_enabled  = try(site_config.value.vnet_route_all_enabled, null)
      app_command_line        = try(site_config.value.app_command_line, null)

      dynamic "application_stack" {
        for_each = try(site_config.value.application_stack, null) == null ? [] : [site_config.value.application_stack]
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
  }

  dynamic "connection_string" {
    for_each = var.connection_strings
    content {
      name  = connection_string.key
      type  = connection_string.value.type
      value = connection_string.value.value
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
      require_https                           = try(auth_settings_v2.value.require_https, null)
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
}

resource "azurerm_linux_web_app" "this" {
  count = local.is_linux ? 1 : 0

  name                                           = var.name
  resource_group_name                            = var.resource_group_name
  location                                       = var.location
  service_plan_id                                = var.service_plan_id
  public_network_access_enabled                  = var.public_network_access_enabled
  https_only                                     = var.https_only
  enabled                                        = var.enabled
  client_affinity_enabled                        = var.client_affinity_enabled
  client_certificate_enabled                     = var.client_certificate_enabled
  client_certificate_mode                        = var.client_certificate_mode
  client_certificate_exclusion_paths             = var.client_certificate_exclusion_paths
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
    for_each = var.site_config == null ? [] : [var.site_config]
    content {
      always_on               = try(site_config.value.always_on, null)
      ftps_state              = try(site_config.value.ftps_state, null)
      health_check_path       = try(site_config.value.health_check_path, null)
      http2_enabled           = try(site_config.value.http2_enabled, null)
      minimum_tls_version     = try(site_config.value.minimum_tls_version, null)
      scm_minimum_tls_version = try(site_config.value.scm_minimum_tls_version, null)
      use_32_bit_worker       = try(site_config.value.use_32_bit_worker, null)
      websockets_enabled      = try(site_config.value.websockets_enabled, null)
      vnet_route_all_enabled  = try(site_config.value.vnet_route_all_enabled, null)
      app_command_line        = try(site_config.value.app_command_line, null)

      dynamic "application_stack" {
        for_each = try(site_config.value.application_stack, null) == null ? [] : [site_config.value.application_stack]
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
  }

  dynamic "connection_string" {
    for_each = var.connection_strings
    content {
      name  = connection_string.key
      type  = connection_string.value.type
      value = connection_string.value.value
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
      require_https                           = try(auth_settings_v2.value.require_https, null)
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
}
