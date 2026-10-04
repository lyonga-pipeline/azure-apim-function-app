variable "name" {
  description = "Resource name. Changing this forces a new resource."
  type        = string
}
variable "resource_group_name" {
  description = "Resource group. Changing this forces a new resource."
  type        = string
}
variable "location" {
  description = "Azure region. Changing this forces a new resource."
  type        = string
}
variable "type" {
  type    = string
  default = "ExpressRoute"

  validation {
    condition     = contains(["ExpressRoute", "Vpn"], var.type)
    error_message = "type must be ExpressRoute or Vpn."
  }
}
variable "vpn_type" {
  type    = string
  default = "RouteBased"

  validation {
    condition     = contains(["RouteBased", "PolicyBased"], var.vpn_type)
    error_message = "vpn_type must be RouteBased or PolicyBased."
  }
}
variable "sku" {
  type    = string
  default = "ErGw1AZ"
}
variable "active_active" {
  type    = bool
  default = false
}
variable "bgp_enabled" {
  description = "Whether BGP is enabled on the gateway. Preferred over deprecated enable_bgp."
  type        = bool
  default     = null
}
variable "enable_bgp" {
  description = "Deprecated compatibility input. Use bgp_enabled for AzureRM v4+."
  type        = bool
  default     = null
}
variable "generation" {
  type    = string
  default = null
}
variable "ip_configurations" {
  type = map(object({
    public_ip_address_id          = string
    subnet_id                     = string
    private_ip_address_allocation = optional(string, "Dynamic")
  }))

  validation {
    condition     = length(var.ip_configurations) > 0
    error_message = "ip_configurations must contain at least one entry."
  }

  validation {
    condition = alltrue([
      for cfg in values(var.ip_configurations) :
      can(regex("(?i)/subnets/GatewaySubnet$", cfg.subnet_id))
    ])
    error_message = "Each ip_configurations subnet_id must reference the hub GatewaySubnet."
  }

  validation {
    condition = alltrue([
      for cfg in values(var.ip_configurations) :
      contains(["Dynamic", "Static"], try(cfg.private_ip_address_allocation, "Dynamic"))
    ])
    error_message = "private_ip_address_allocation must be Dynamic or Static."
  }
}
variable "tags" {
  description = "Tags applied to the resource."
  type        = map(string)
  default     = {}
}
