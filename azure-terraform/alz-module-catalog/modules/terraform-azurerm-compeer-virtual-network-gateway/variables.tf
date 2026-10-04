variable "name" {
  description = "Resource name. Changing this forces a new resource."
  type        = string

  validation {
    # Microsoft.Network/virtualNetworkGateways naming rule: 1-80 chars,
    # alphanumerics/underscores/periods/hyphens, start alphanumeric, end
    # alphanumeric or underscore (Azure resource-name-rules reference).
    condition     = can(regex("^[A-Za-z0-9]([A-Za-z0-9_.-]{0,78}[A-Za-z0-9_])?$", var.name))
    error_message = "name must be 1-80 characters (alphanumerics, underscores, periods, hyphens), start with an alphanumeric, and end with an alphanumeric or underscore."
  }
}
variable "resource_group_name" {
  description = "Resource group. Changing this forces a new resource."
  type        = string

  validation {
    condition     = trimspace(var.resource_group_name) != ""
    error_message = "resource_group_name must not be empty."
  }
}
variable "location" {
  description = "Azure region. Changing this forces a new resource."
  type        = string

  validation {
    condition     = trimspace(var.location) != ""
    error_message = "location must not be empty."
  }
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
  description = "Gateway SKU. ExpressRoute gateways use Standard/HighPerformance/UltraPerformance/ErGw*; VPN gateways use Basic/Standard/HighPerformance/VpnGw*. The type/SKU pairing is checked in main.tf."
  type        = string
  default     = "ErGw1AZ"

  validation {
    # azurerm_virtual_network_gateway's documented SKU values.
    condition = contains([
      "Basic", "Standard", "HighPerformance", "UltraPerformance",
      "ErGwScale", "ErGw1AZ", "ErGw2AZ", "ErGw3AZ",
      "VpnGw1", "VpnGw2", "VpnGw3", "VpnGw4", "VpnGw5",
      "VpnGw1AZ", "VpnGw2AZ", "VpnGw3AZ", "VpnGw4AZ", "VpnGw5AZ",
    ], var.sku)
    error_message = "sku must be one of Basic, Standard, HighPerformance, UltraPerformance, ErGwScale, ErGw1AZ, ErGw2AZ, ErGw3AZ, VpnGw1-5, VpnGw1AZ-5AZ."
  }
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

  validation {
    condition     = var.generation == null ? true : contains(["Generation1", "Generation2", "None"], var.generation)
    error_message = "generation must be Generation1, Generation2, or None when set."
  }
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
