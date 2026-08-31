variable "name" {
  description = "Name of the deployment slot. Changing this forces a new resource."
  type        = string
}

variable "app_service_id" {
  description = "Resource ID of the parent azurerm_linux_web_app this slot belongs to. Changing this forces a new resource."
  type        = string
}

variable "https_only" {
  description = "Force HTTPS for the slot."
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Whether the slot is reachable from public networks. Defaults closed."
  type        = bool
  default     = false
}

variable "virtual_network_subnet_id" {
  description = "Subnet ID for regional VNet integration of the slot. null disables integration."
  type        = string
  default     = null
}

variable "app_settings" {
  description = "Slot application settings."
  type        = map(string)
  default     = {}
}

variable "site_config" {
  description = "Slot site configuration. All fields optional; provider defaults apply when omitted."
  type = object({
    always_on                               = optional(bool)
    ftps_state                              = optional(string)
    http2_enabled                           = optional(bool)
    minimum_tls_version                     = optional(string)
    health_check_path                       = optional(string)
    health_check_eviction_time_in_min       = optional(number)
    vnet_route_all_enabled                  = optional(bool)
    worker_count                            = optional(number)
    app_command_line                        = optional(string)
    container_registry_use_managed_identity = optional(bool)
    application_stack = optional(object({
      docker_image_name   = optional(string)
      docker_registry_url = optional(string)
      dotnet_version      = optional(string)
      go_version          = optional(string)
      java_version        = optional(string)
      node_version        = optional(string)
      php_version         = optional(string)
      python_version      = optional(string)
      ruby_version        = optional(string)
    }))
  })
  default = {}
}

variable "identity" {
  description = "Optional managed identity for the slot."
  type = object({
    type         = string
    identity_ids = optional(list(string), [])
  })
  default = null
}

variable "tags" {
  description = "Tags applied to the slot."
  type        = map(string)
  default     = {}
}

variable "timeouts" {
  description = "Optional resource operation timeouts."
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = {}
}
