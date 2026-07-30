variable "name" {
  type = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{2,60}$", var.name))
    error_message = "name must be 2-60 characters and contain only letters, numbers, and hyphens."
  }
}

variable "resource_group_name" { type = string }
variable "location" { type = string }

variable "service_plan_name" {
  type    = string
  default = null
}

variable "service_plan_sku_name" {
  type    = string
  default = "P1v3"
}

variable "os_type" {
  type    = string
  default = "Windows"

  validation {
    condition     = contains(["linux", "windows"], lower(var.os_type))
    error_message = "os_type must be Linux or Windows."
  }
}

variable "worker_count" {
  type    = number
  default = null
}

variable "maximum_elastic_worker_count" {
  type    = number
  default = null
}

variable "per_site_scaling_enabled" {
  type    = bool
  default = false
}

variable "zone_balancing_enabled" {
  type    = bool
  default = false
}

variable "public_network_access_enabled" {
  type    = bool
  default = false
}

variable "virtual_network_subnet_id" {
  type    = string
  default = null
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
  default = {
    type         = "SystemAssigned"
    identity_ids = []
  }

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
      tomcat_version               = optional(string)
    }))
  })
  default = {}

  validation {
    condition     = var.site_config.ftps_state == null || contains(["Disabled", "FtpsOnly"], var.site_config.ftps_state)
    error_message = "site_config.ftps_state must be Disabled or FtpsOnly."
  }

  validation {
    condition     = var.site_config.minimum_tls_version == null || contains(["1.2", "1.3"], var.site_config.minimum_tls_version)
    error_message = "site_config.minimum_tls_version must be 1.2 or 1.3."
  }

  validation {
    condition     = var.site_config.scm_minimum_tls_version == null || contains(["1.2", "1.3"], var.site_config.scm_minimum_tls_version)
    error_message = "site_config.scm_minimum_tls_version must be 1.2 or 1.3."
  }
}

variable "app_settings" {
  type    = map(string)
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
