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
variable "storage" {
  type = object({
    account_name          = optional(string)
    account_access_key    = optional(string)
    uses_managed_identity = optional(bool, false)
    key_vault_secret_id   = optional(string)
  })
}
variable "public_network_access_enabled" {
  type    = bool
  default = false
}
variable "https_only" {
  type    = bool
  default = true
}
variable "functions_extension_version" {
  type    = string
  default = "~4"
}
variable "enabled" {
  type    = bool
  default = true
}
variable "builtin_logging_enabled" {
  type    = bool
  default = true
}
variable "client_certificate_enabled" {
  type    = bool
  default = false
}
variable "client_certificate_mode" {
  type    = string
  default = "Required"
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
  default = true
}
variable "webdeploy_publish_basic_authentication_enabled" {
  type    = bool
  default = true
}
variable "identity" {
  type = object({
    type         = string
    identity_ids = optional(list(string), [])
  })
  default = null
}
variable "site_config" {
  type = object({
    always_on                              = optional(bool)
    api_definition_url                     = optional(string)
    app_command_line                       = optional(string)
    application_insights_connection_string = optional(string)
    application_insights_key               = optional(string)
    ftps_state                             = optional(string)
    health_check_path                      = optional(string)
    http2_enabled                          = optional(bool)
    minimum_tls_version                    = optional(string)
    scm_minimum_tls_version                = optional(string)
    use_32_bit_worker                      = optional(bool)
    websockets_enabled                     = optional(bool)
    vnet_route_all_enabled                 = optional(bool)
    application_stack = optional(object({
      dotnet_version              = optional(string)
      java_version                = optional(string)
      node_version                = optional(string)
      powershell_core_version     = optional(string)
      python_version              = optional(string)
      use_dotnet_isolated_runtime = optional(bool)
      use_custom_runtime          = optional(bool)
    }))
  })
  default = null
}
variable "connection_strings" {
  type = map(object({
    type  = string
    value = string
  }))
  default = {}
}
variable "backup" {
  type = object({
    name                = string
    storage_account_url = string
    enabled             = optional(bool, true)
    schedule = object({
      frequency_interval       = number
      frequency_unit           = string
      keep_at_least_one_backup = optional(bool, true)
      retention_period_days    = optional(number)
      start_time               = optional(string)
    })
  })
  default = null
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
