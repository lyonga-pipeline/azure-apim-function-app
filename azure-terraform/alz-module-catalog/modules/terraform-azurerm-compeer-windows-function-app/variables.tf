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

variable "public_network_access_enabled" {
  description = "Should public network access be enabled for the Web App."
  type        = bool
  default     = false
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

variable "builtin_logging_enabled" {
  description = "hould built in logging be enabled. Configures AzureWebJobsDashboard app setting based on the configured storage setting."
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

variable "content_share_force_disabled" {
  description = "Should Content Share Settings be disabled."
  type        = bool
  default     = false
}

variable "daily_memory_time_quota" {
  description = "The amount of memory in gigabyte-seconds that your application is allowed to consume per day. Setting this value only affects function apps under the consumption plan."
  type        = number
  default     = 0
}

variable "enabled" {
  description = "Should the Windows Web App be enabled? Defaults to true."
  type        = bool
  default     = true
}

variable "ftp_publish_basic_authentication_enabled" {
  description = "Should the default FTP Basic Authentication publishing profile be enabled."
  type        = bool
  default     = true
}

variable "functions_extension_version" {
  description = "The runtime version associated with the Function App. Defaults to ~4."
  type        = string
  default     = "~4"
}

variable "https_only" {
  description = "Should the Windows Web App require HTTPS connections."
  type        = bool
  default     = true
}

variable "key_vault_reference_identity_id" {
  description = "The User Assigned Identity ID used for accessing KeyVault secrets. The identity must be assigned to the application in the identity block."
  type        = string
  default     = null
}

variable "storage_account_name" {
  description = "The backend storage account name which will be used by this Function App."
  type        = string
  default     = null
}

variable "storage_key_vault_secret_id" {
  description = "The access key which will be used to access the backend storage account for the Function App. Conflicts with storage_uses_managed_identity."
  type        = string
  default     = null
}

variable "storage_uses_managed_identity" {
  description = "Should the Function App use Managed Identity to access the storage account. Conflicts with storage_account_access_key."
  type        = bool
  default     = false
}

variable "storage_account_access_key" {
  description = " The access key which will be used to access the backend storage account for the Function App. Conflicts with storage_uses_managed_identity."
  type        = string
  sensitive   = true
  default     = null
}

variable "webdeploy_publish_basic_authentication_enabled" {
  description = "Should the default Web Deploy Basic Authentication publishing profile be enabled."
  type        = bool
  default     = true
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

variable "site_config" {
  description = "Configuration for each site"
  type = list(object({
    always_on                              = optional(bool)
    api_definition_url                     = optional(string)
    api_management_api_id                  = optional(string)
    app_command_line                       = optional(string)
    app_scale_limit                        = optional(number)
    application_insights_connection_string = optional(string)
    application_insights_key               = optional(string)
    default_documents                      = optional(list(string))
    elastic_instance_minimum               = optional(number)
    ftps_state                             = optional(string)
    health_check_path                      = optional(string)
    health_check_eviction_time_in_min      = optional(number)
    http2_enabled                          = optional(bool)
    load_balancing_mode                    = optional(string)
    managed_pipeline_mode                  = optional(string)
    minimum_tls_version                    = optional(string)
    pre_warmed_instance_count              = optional(number)
    remote_debugging_enabled               = optional(bool)
    remote_debugging_version               = optional(string)
    runtime_scale_monitoring_enabled       = optional(bool)
    scm_minimum_tls_version                = optional(string)
    scm_use_main_ip_restriction            = optional(bool)
    use_32_bit_worker                      = optional(bool)
    vnet_route_all_enabled                 = optional(bool)
    websockets_enabled                     = optional(bool)
    worker_count                           = optional(number)
    application_stack = optional(object({
      dotnet_version              = optional(string)
      use_dotnet_isolated_runtime = optional(bool)
      java_version                = optional(string)
      node_version                = optional(string)
      powershell_core_version     = optional(string)
      use_custom_runtime          = optional(bool)
    }))
    app_service_logs = optional(object({
      disk_quota_mb         = optional(number)
      retention_period_days = optional(number)
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
    identity_ids = list(string)
  }))
  default = []
}

variable "sticky_settings" {
  description = "Typically used for sticky session configurations."
  type = list(object({
    app_setting_names       = list(string)
    connection_string_names = list(string)
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
