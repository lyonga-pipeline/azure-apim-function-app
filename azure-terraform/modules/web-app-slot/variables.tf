variable "name" {
  type = string
}

variable "app_service_id" {
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

variable "service_plan_id" {
  type    = string
  default = null
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
  default = {}

  validation {
    condition     = try(var.site_config.ftps_state, null) == null || contains(["Disabled", "FtpsOnly"], var.site_config.ftps_state)
    error_message = "site_config.ftps_state must be Disabled or FtpsOnly."
  }

  validation {
    condition     = try(var.site_config.minimum_tls_version, null) == null || contains(["1.2", "1.3"], var.site_config.minimum_tls_version)
    error_message = "site_config.minimum_tls_version must be 1.2 or 1.3."
  }

  validation {
    condition     = try(var.site_config.scm_minimum_tls_version, null) == null || contains(["1.2", "1.3"], var.site_config.scm_minimum_tls_version)
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

variable "app_settings" {
  type    = map(string)
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
