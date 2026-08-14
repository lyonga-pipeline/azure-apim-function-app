variable "private_dns_zone_name" {
  description = "The name of the Private DNS Zone. Must be a valid domain name. Changing this forces a new resource to be created."
  type        = string

  validation {
    condition     = length(trimspace(var.private_dns_zone_name)) > 0 && can(regex("^[A-Za-z0-9][A-Za-z0-9.-]+[A-Za-z0-9]$", var.private_dns_zone_name))
    error_message = "private_dns_zone_name must be a non-empty DNS zone name."
  }
}

variable "resource_group_name" {
  description = "Specifies the resource group where the resource exists. Changing this forces a new resource to be created."
  type        = string
}

variable "soa_record" {
  description = "value"
  type = list(object({
    email        = string
    expire_time  = optional(number)
    minimum_ttl  = optional(number)
    refresh_time = optional(number)
    retry_time   = optional(number)
    ttl          = optional(number)
    tags         = optional(map(string))
  }))
  default = []
}

variable "private_dns_zone_tags" {
  description = "value"
  type        = map(string)
  default     = {}
}

variable "vnet_link_name" {
  description = "The name of the Private DNS Zone Virtual Network Link. Changing this forces a new resource to be created."
  type        = string
}

variable "virtual_network_id" {
  description = "The ID of the Virtual Network that should be linked to the DNS Zone. Changing this forces a new resource to be created."
  type        = string
}

variable "registration_enabled" {
  description = "Is auto-registration of virtual machine records in the virtual network in the Private DNS zone enabled? "
  type        = bool
  default     = false
}

variable "vnet_link_tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = {}
}
