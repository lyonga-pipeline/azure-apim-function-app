variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "os_type" {
  type    = string
  default = "Windows"
  validation {
    condition     = contains(["linux", "windows"], lower(var.os_type))
    error_message = "os_type must be Linux or Windows."
  }
}
variable "service_plan_id" { type = string }
variable "public_network_access_enabled" {
  type    = bool
  default = false
}
variable "https_only" {
  type    = bool
  default = true
}
variable "enabled" {
  type    = bool
  default = true
}
variable "client_affinity_enabled" {
  type    = bool
  default = false
}
variable "client_certificate_enabled" {
  type    = bool
  default = false
}
variable "client_certificate_mode" {
  type    = string
  default = "Required"

  validation {
    condition     = contains(["Required", "Optional", "OptionalInteractiveUser"], var.client_certificate_mode)
    error_message = "client_certificate_mode must be Required, Optional, or OptionalInteractiveUser."
  }
}
variable "client_certificate_exclusion_paths" {
  type    = string
  default = null
}
variable "key_vault_reference_identity_id" {
  type    = string
  default = null
}
variable "virtual_network_backup_restore_enabled" {
  type    = bool
  default = false
}
variable "ftp_publish_basic_authentication_enabled" {
  type    = bool
  default = false
}
variable "webdeploy_publish_basic_authentication_enabled" {
  type    = bool
  default = false
}
variable "identity" {
  type = object({
    type         = string
    identity_ids = optional(list(string), [])
  })
  default = null

  validation {
    condition = var.identity == null || contains([
      "SystemAssigned",
      "UserAssigned",
      "SystemAssigned, UserAssigned"
    ], var.identity.type)
    error_message = "identity.type must be SystemAssigned, UserAssigned, or 'SystemAssigned, UserAssigned'."
  }
}
variable "site_config" {
  type = object({
    always_on               = optional(bool)
    ftps_state              = optional(string)
    health_check_path       = optional(string)
    http2_enabled           = optional(bool)
    minimum_tls_version     = optional(string)
    scm_minimum_tls_version = optional(string)
    use_32_bit_worker       = optional(bool)
    websockets_enabled      = optional(bool)
    vnet_route_all_enabled  = optional(bool)
    app_command_line        = optional(string)
    application_stack = optional(object({
      current_stack                = optional(string)
      docker_image_name            = optional(string)
      docker_registry_url          = optional(string)
      docker_registry_username     = optional(string)
      docker_registry_password     = optional(string)
      dotnet_core_version          = optional(string)
      dotnet_version               = optional(string)
      go_version                   = optional(string)
      java_container               = optional(string)
      java_container_version       = optional(string)
      java_embedded_server_enabled = optional(bool)
      java_server                  = optional(string)
      java_server_version          = optional(string)
      java_version                 = optional(string)
      node_version                 = optional(string)
      php_version                  = optional(string)
      python                       = optional(bool)
      python_version               = optional(string)
      ruby_version                 = optional(string)
      tomcat_version               = optional(string)
    }))
  })
  default = null

  validation {
    condition     = var.site_config == null || try(var.site_config.ftps_state, null) == null || contains(["Disabled", "FtpsOnly"], var.site_config.ftps_state)
    error_message = "site_config.ftps_state must be Disabled or FtpsOnly."
  }

  validation {
    condition     = var.site_config == null || try(var.site_config.minimum_tls_version, null) == null || contains(["1.2", "1.3"], var.site_config.minimum_tls_version)
    error_message = "site_config.minimum_tls_version must be 1.2 or 1.3."
  }

  validation {
    condition     = var.site_config == null || try(var.site_config.scm_minimum_tls_version, null) == null || contains(["1.2", "1.3"], var.site_config.scm_minimum_tls_version)
    error_message = "site_config.scm_minimum_tls_version must be 1.2 or 1.3."
  }
}
variable "connection_strings" {
  type = map(object({
    type  = string
    value = string
  }))
  default = {}
}
variable "sticky_settings" {
  type = object({
    app_setting_names       = optional(list(string), [])
    connection_string_names = optional(list(string), [])
  })
  default = null
}
variable "auth_settings_v2" {
  type = object({
    auth_enabled                            = optional(bool)
    config_file_path                        = optional(string)
    default_provider                        = optional(string)
    excluded_paths                          = optional(list(string), [])
    forward_proxy_convention                = optional(string)
    forward_proxy_custom_host_header_name   = optional(string)
    forward_proxy_custom_scheme_header_name = optional(string)
    http_route_api_prefix                   = optional(string)
    require_authentication                  = optional(bool)
    require_https                           = optional(bool)
    runtime_version                         = optional(string)
    unauthenticated_action                  = optional(string)
    active_directory_v2 = optional(object({
      client_id                            = string
      tenant_auth_endpoint                 = string
      allowed_applications                 = optional(list(string), [])
      allowed_audiences                    = optional(list(string), [])
      allowed_groups                       = optional(list(string), [])
      allowed_identities                   = optional(list(string), [])
      client_secret_certificate_thumbprint = optional(string)
      client_secret_setting_name           = optional(string)
      jwt_allowed_client_applications      = optional(list(string), [])
      jwt_allowed_groups                   = optional(list(string), [])
      login_parameters                     = optional(map(string), {})
      www_authentication_disabled          = optional(bool, false)
    }))
    apple_v2 = optional(object({
      client_id                  = string
      client_secret_setting_name = string
    }))
    azure_static_web_app_v2 = optional(object({
      client_id = string
    }))
    custom_oidc_v2 = optional(map(object({
      client_id                     = string
      openid_configuration_endpoint = string
      name_claim_type               = optional(string)
      scopes                        = optional(list(string), [])
    })), {})
    facebook_v2 = optional(object({
      app_id                  = string
      app_secret_setting_name = string
      graph_api_version       = optional(string)
      login_scopes            = optional(list(string), [])
    }))
    github_v2 = optional(object({
      client_id                  = string
      client_secret_setting_name = string
      login_scopes               = optional(list(string), [])
    }))
    google_v2 = optional(object({
      client_id                  = string
      client_secret_setting_name = string
      allowed_audiences          = optional(list(string), [])
      login_scopes               = optional(list(string), [])
    }))
    login = optional(object({
      allowed_external_redirect_urls    = optional(list(string), [])
      cookie_expiration_convention      = optional(string)
      cookie_expiration_time            = optional(string)
      logout_endpoint                   = optional(string)
      nonce_expiration_time             = optional(string)
      preserve_url_fragments_for_logins = optional(bool)
      token_refresh_extension_time      = optional(number)
      token_store_enabled               = optional(bool)
      token_store_path                  = optional(string)
      token_store_sas_setting_name      = optional(string)
      validate_nonce                    = optional(bool)
    }))
    microsoft_v2 = optional(object({
      client_id                  = string
      client_secret_setting_name = string
      allowed_audiences          = optional(list(string), [])
      login_scopes               = optional(list(string), [])
    }))
    twitter_v2 = optional(object({
      consumer_key                 = string
      consumer_secret_setting_name = string
    }))
  })
  default = null
}
variable "app_settings" {
  type    = map(string)
  default = {}
}
variable "tags" {
  type    = map(string)
  default = {}
}
