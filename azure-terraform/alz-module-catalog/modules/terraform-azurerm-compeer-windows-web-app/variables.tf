variable "location" {
  description = "The Azure Region where the Windows Web App should exist. Changing this forces a new Windows Web App to be created."
  type        = string
}

variable "name" {
  description = "The name which should be used for this Windows Web App. Changing this forces a new Windows Web App to be created."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the Resource Group where the Windows Web App should exist. Changing this forces a new Windows Web App to be created."
  type        = string
}

variable "service_plan_id" {
  description = "The ID of the Service Plan that this Windows App Service will be created in."
  type        = string
}

variable "virtual_network_subnet_id" {
  description = "The subnet id which will be used by this Web App for regional virtual network integration."
  type        = string
  default     = null
}

variable "app_settings" {
  description = "A map of key-value pairs of App Settings."
  type        = map(string)
  default     = null
}

variable "client_affinity_enabled" {
  description = "Should Client Affinity be enabled?"
  type        = bool
  default     = false
}

variable "client_certificate_enabled" {
  description = "Should Client Certificates be enabled?"
  type        = bool
  default     = false
}

variable "client_certificate_mode" {
  description = "The Client Certificate mode. Possible values are Required, Optional, and OptionalInteractiveUser. This property has no effect when client_cert_enabled is false"
  type        = string
  default     = null
}

variable "client_certificate_exclusion_paths" {
  description = " Paths to exclude when using client certificates, separated by ;"
  type        = string
  default     = null
}

variable "enabled" {
  description = "Should the Windows Web App be enabled? Defaults to true."
  type        = bool
  default     = true
}

variable "https_only" {
  description = "Should the Windows Web App require HTTPS connections."
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Should public network access be enabled for the Web App."
  type        = bool
  default     = false
}

variable "key_vault_reference_identity_id" {
  description = "The User Assigned Identity ID used for accessing KeyVault secrets. The identity must be assigned to the application in the identity block."
  type        = string
  default     = null
}

variable "zip_deploy_file" {
  description = "The local path and filename of the Zip packaged application to deploy to this Windows Web App."
  type        = string
  default     = null
}

variable "tags" {
  description = "A mapping of tags which should be assigned to the Windows Web App."
  type        = map(string)
  default     = {}
}

# Diagnostic settings are composed by the dedicated diagnostic-settings module
# at the pattern layer, not owned here.

variable "site_config" {
  description = "Configuration for each site"
  type = list(object({
    always_on                                     = optional(bool)
    api_definition_url                            = optional(string)
    api_management_api_id                         = optional(string)
    app_command_line                              = optional(string)
    container_registry_managed_identity_client_id = optional(string)
    container_registry_use_managed_identity       = optional(bool)
    default_documents                             = optional(list(string))
    ftps_state                                    = optional(string)
    health_check_path                             = optional(string)
    health_check_eviction_time_in_min             = optional(number)
    http2_enabled                                 = optional(bool)
    load_balancing_mode                           = optional(string)
    local_mysql_enabled                           = optional(bool)
    managed_pipeline_mode                         = optional(string)
    minimum_tls_version                           = optional(string)
    remote_debugging_enabled                      = optional(bool)
    remote_debugging_version                      = optional(string)
    scm_minimum_tls_version                       = optional(string)
    scm_use_main_ip_restriction                   = optional(bool)
    use_32_bit_worker                             = optional(bool)
    vnet_route_all_enabled                        = optional(bool)
    websockets_enabled                            = optional(bool)
    worker_count                                  = optional(number)
    application_stack = optional(object({
      current_stack                = optional(string)
      docker_image_name            = optional(string)
      docker_registry_url          = optional(string)
      docker_registry_username     = optional(string)
      docker_registry_password     = optional(string)
      dotnet_version               = optional(string)
      dotnet_core_version          = optional(string)
      tomcat_version               = optional(string)
      java_embedded_server_enabled = optional(bool)
      java_version                 = optional(string)
      node_version                 = optional(string)
      php_version                  = optional(string)
      python                       = optional(string)
    }))
    auto_heal_setting = optional(object({
      action = optional(object({
        action_type                    = optional(string)
        minimum_process_execution_time = optional(string)
        custom_action = optional(object({
          executable = optional(string)
          parameters = optional(string)
        }))
      }))
      trigger = optional(object({
        private_memory_kb = optional(string)
        requests = optional(list(object({
          count    = optional(string)
          interval = optional(string)
        })))
        slow_request = optional(object({
          count      = optional(string)
          interval   = optional(string)
          time_taken = optional(string)
        }))
        slow_request_with_path = optional(object({
          count      = optional(string)
          interval   = optional(string)
          time_taken = optional(string)
          path       = optional(string)
        }))
        status_code = optional(object({
          count             = optional(string)
          interval          = optional(string)
          status_code_range = optional(string)
          path              = optional(string)
          sub_status        = optional(string)
          win32_status      = optional(string)
        }))
      }))
    }))
    cors = optional(object({
      allowed_origins     = list(string)
      support_credentials = optional(bool)
    }))
    ip_restriction = optional(object({
      action                    = optional(string)
      ip_address                = optional(string)
      name                      = optional(string)
      priority                  = optional(number)
      service_tag               = optional(string)
      virtual_network_subnet_id = optional(string)
      headers = optional(object({
        x_azure_fdid      = optional(list(string))
        x_fd_health_probe = optional(string)
        x_forwarded_for   = optional(list(string))
        x_forwarded_host  = optional(list(string))
      }))
    }))
    scm_ip_restriction = optional(object({
      action                    = optional(string)
      ip_address                = optional(string)
      name                      = optional(string)
      priority                  = optional(number)
      service_tag               = optional(string)
      virtual_network_subnet_id = optional(string)
      headers = optional(object({
        x_azure_fdid      = optional(list(string))
        x_fd_health_probe = optional(string)
        x_forwarded_for   = optional(list(string))
        x_forwarded_host  = optional(list(string))
      }))
    }))
    virtual_application = optional(object({
      physical_path = string
      preload       = bool
      virtual_path  = string
      virtual_directory = optional(object({
        physical_path = optional(string)
        virtual_path  = optional(string)
      }))
    }))
  }))
  default = [{}]

  validation {
    condition     = length(var.site_config) == 1
    error_message = "site_config must contain exactly one block ([{...}]); it maps to the required singleton site_config block."
  }
}

variable "auth_settings" {
  description = "Authentication settings configuration"
  type = list(object({
    enabled                        = bool
    additional_login_parameters    = optional(map(string))
    allowed_external_redirect_urls = optional(list(string))
    runtime_version                = optional(string)
    token_refresh_extension_hours  = optional(number)
    token_store_enabled            = optional(bool)
    unauthenticated_client_action  = optional(string)
    active_directory = optional(object({
      client_id                  = string
      allowed_audiences          = optional(list(string))
      client_secret              = optional(string)
      client_secret_setting_name = optional(string)
    }))
    microsoft = optional(object({
      client_id                  = string
      client_secret              = optional(string)
      client_secret_setting_name = optional(string)
      oauth_scopes               = optional(list(string))
    }))
  }))
  default = []
}

variable "backup" {
  description = "Backup settings configuration"
  type = list(object({
    name                = string
    storage_account_url = string
    enabled             = bool
    schedule = optional(object({
      frequency_interval       = string
      frequency_unit           = string
      keep_at_least_one_backup = optional(bool)
      retention_period_days    = optional(number)
      start_time               = optional(string)
    }))
  }))
  default = []
}

variable "connection_string" {
  description = "App connection strings, keyed by connection-string name (the map key becomes the Azure connection_string name)."
  type = map(object({
    type  = string
    value = string
  }))
  default = {}
}

variable "identity" {
  description = "For setting managed identity for accessing Azure services."
  type = list(object({
    type         = string
    identity_ids = optional(list(string))
  }))
  default = []
}

variable "logs" {
  description = "Logging settings configuration"
  type = list(object({
    application_logs = optional(object({
      detailed_error_messages = optional(bool)
      failed_request_tracing  = optional(bool)
      file_system_level       = optional(string)
      azure_blob_storage = optional(object({
        level             = string
        retention_in_days = optional(number)
        sas_url           = optional(string)
      }))
    }))
    http_logs = optional(object({
      azure_blob_storage = optional(list(object({
        retention_in_days = optional(number)
        sas_url           = optional(string)
      })))
      file_system = optional(object({
        retention_in_days = optional(number)
        retention_in_mb   = optional(number)
      }))
    }))
  }))
  default = []
}

variable "sticky_settings" {
  description = "Typically used for sticky session configurations."
  type = list(object({
    app_setting_names       = optional(list(string), [])
    connection_string_names = optional(list(string), [])
  }))
  default = []
}

variable "storage_account" {
  description = "To link Azure storage accounts."
  type = list(object({
    access_key   = string
    account_name = string
    name         = string
    share_name   = string
    type         = string
    mount_path   = optional(string)
  }))
  default = []
}

variable "ftp_publish_basic_authentication_enabled" {
  description = "Should FTP publish profile use basic authentication. Defaults to true."
  type        = bool
  default     = true
}

variable "webdeploy_publish_basic_authentication_enabled" {
  description = "Should WebDeploy publish profile use basic authentication. Defaults to true."
  type        = bool
  default     = true
}
