variable "name" {
  description = "The name of the Private Endpoint."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the Resource Group where the Private Endpoint should exist."
  type        = string
}

variable "custom_network_interface_name" {
  description = "The custom name of the network interface attached to the private endpoint. Changing this forces a new resource to be created."
  type        = string
  default     = null
}

variable "location" {
  description = "The Azure region where the Private Endpoint should exist."
  type        = string
}

variable "edge_zone" {
  description = "Optional Azure edge zone where the Private Endpoint should exist."
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "The ID of the Subnet from which Private IP Addresses will be allocated for this Private Endpoint."
  type        = string
}

variable "private_service_connections" {
  description = "A list of maps containing private service connection details"
  type = list(object({
    name                              = string
    is_manual_connection              = bool
    private_connection_resource_id    = optional(string)
    subresource_names                 = optional(list(string))
    request_message                   = optional(string)
    private_connection_resource_alias = optional(string)
  }))
  default = []

  validation {
    condition     = length(var.private_service_connections) == 1
    error_message = "Exactly one private_service_connections entry is required by Azure for this resource."
  }

  validation {
    condition = alltrue([
      for connection in var.private_service_connections :
      (try(connection.private_connection_resource_id, null) != null) != (try(connection.private_connection_resource_alias, null) != null)
    ])
    error_message = "Each private_service_connections entry must set exactly one of private_connection_resource_id or private_connection_resource_alias."
  }
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = {}
}

variable "ip_configurations" {
  description = "Configuration for IP Configurations."
  type = list(object({
    name               = string
    private_ip_address = string
    subresource_name   = string
    member_name        = string
  }))
  default = []
}

variable "timeouts" {
  description = "Optional resource operation timeouts."
  type = object({
    create = optional(string)
    update = optional(string)
    read   = optional(string)
    delete = optional(string)
  })
  default = {}
}

# Built-in DNS-registration policies match automatically approved service connections.
variable "policy_registration_approved" {
  description = "Explicit acknowledgement that platform DNS policies and their zone permissions are deployed. This is not live compliance evidence."
  type        = bool
  validation {
    condition     = var.policy_registration_approved
    error_message = "Deploy and verify central DNS registration before selecting a policy-owned endpoint."
  }
}
