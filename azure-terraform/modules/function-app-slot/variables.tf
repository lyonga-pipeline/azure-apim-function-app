variable "name" {
  type = string
}

variable "function_app_id" {
  type = string
}

variable "os_type" {
  type    = string
  default = "Windows"
  validation {
    condition     = contains(["Linux", "Windows", "linux", "windows"], var.os_type)
    error_message = "os_type must be Linux or Windows."
  }
}

variable "storage" {
  type = object({
    account_name          = optional(string)
    account_access_key    = optional(string)
    uses_managed_identity = optional(bool)
    key_vault_secret_id   = optional(string)
  })
  default = {}

  validation {
    condition = (
      try(var.storage.key_vault_secret_id, null) != null ||
      try(var.storage.account_name, null) != null
    )
    error_message = "Set either storage.account_name or storage.key_vault_secret_id for the slot storage contract."
  }
}

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

variable "functions_extension_version" {
  type    = string
  default = "~4"
}

variable "client_certificate_enabled" {
  type    = bool
  default = false
}

variable "client_certificate_mode" {
  type    = string
  default = "Required"
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
  default = {}
}

variable "connection_strings" {
  type = map(object({
    type  = string
    value = string
  }))
  default = {}
}

variable "app_settings" {
  type    = map(string)
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
