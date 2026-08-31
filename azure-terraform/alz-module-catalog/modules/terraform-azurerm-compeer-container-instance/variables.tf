variable "container_name" {
  type        = string
  description = "Name of the container group. Changing this forces a new resource."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group the container group is created in. Changing this forces a new resource."
}

variable "location" {
  type        = string
  description = "Azure region. Changing this forces a new resource."
}

variable "os_type" {
  type        = string
  description = "The OS for the container group. Allowed values are `Linux` and `Windows`. Changing this forces a new resource."
  default     = "Linux"

  validation {
    condition     = contains(["Linux", "Windows"], var.os_type)
    error_message = "os_type must be Linux or Windows."
  }
}

variable "ip_address_type" {
  type        = string
  description = "IP address type of the container group. Allowed values `Public`, `Private`, and `None`. Changing this forces a new resource."
  default     = "Private"

  validation {
    condition     = contains(["Public", "Private", "None"], var.ip_address_type)
    error_message = "ip_address_type must be Public, Private, or None."
  }
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet resource IDs for the container group. Required only when ip_address_type is Private."
  default     = []
}

variable "dns_config" {
  type = map(object({
    nameservers    = list(string)
    search_domains = optional(list(string))
  }))
  description = "Optional custom DNS configuration, keyed by a caller-stable name (the provider consumes a single dns_config block)."
  default     = {}
}

variable "container_info" {
  type = map(object({
    name                         = string
    image                        = string
    cpu                          = number
    memory                       = number
    environment_variables        = optional(map(string))
    secure_environment_variables = optional(map(string))
    ports = optional(map(object({
      port     = number
      protocol = string
    })), {})
  }))
  description = "Containers in the group, keyed by a caller-stable name. At least one entry is required."

  validation {
    condition     = length(var.container_info) > 0
    error_message = "container_info must contain at least one container."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the container group."
  default     = {}
}
