variable "name" {
  description = "Name of the virtual network. Changing this forces a new resource."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the VNet and subnets are created in."
  type        = string
}

variable "location" {
  description = "Azure region for the VNet."
  type        = string
}

variable "address_space" {
  description = "VNet address space (one or more CIDRs)."
  type        = list(string)

  validation {
    condition     = length(var.address_space) > 0
    error_message = "address_space must contain at least one CIDR."
  }
}

variable "dns_servers" {
  description = "Custom DNS servers for the VNet. null keeps Azure-provided DNS."
  type        = list(string)
  default     = null
}

variable "bgp_community" {
  description = "BGP community advertised over ExpressRoute, e.g. 12076:20001."
  type        = string
  default     = null
}

variable "edge_zone" {
  description = "Edge zone the VNet is created in. Changing this forces a new resource."
  type        = string
  default     = null
}

variable "flow_timeout_in_minutes" {
  description = "Connection flow timeout in minutes (4-30)."
  type        = number
  default     = null

  validation {
    condition     = var.flow_timeout_in_minutes == null ? true : (var.flow_timeout_in_minutes >= 4 && var.flow_timeout_in_minutes <= 30)
    error_message = "flow_timeout_in_minutes must be between 4 and 30."
  }
}

variable "private_endpoint_vnet_policies" {
  description = "Private Endpoint VNet policy mode (Disabled or Basic)."
  type        = string
  default     = null

  validation {
    condition     = var.private_endpoint_vnet_policies == null ? true : contains(["Disabled", "Basic"], var.private_endpoint_vnet_policies)
    error_message = "private_endpoint_vnet_policies must be Disabled or Basic."
  }
}

variable "ddos_protection_plan_id" {
  description = "ID of an externally managed DDoS Protection Plan to associate. null means no association."
  type        = string
  default     = null
}

variable "encryption" {
  description = "Optional VNet encryption. null disables the encryption block."
  type = object({
    enforcement = optional(string, "AllowUnencrypted")
  })
  default = null

  validation {
    condition     = var.encryption == null ? true : contains(["AllowUnencrypted", "DropUnencrypted"], var.encryption.enforcement)
    error_message = "encryption.enforcement must be AllowUnencrypted or DropUnencrypted."
  }
}

variable "subnets" {
  description = <<-EOT
    Subnets keyed by subnet name (the map key is the Azure subnet name). Adding or
    removing a key never re-creates unrelated subnets.
  EOT
  type = map(object({
    address_prefixes                              = list(string)
    service_endpoints                             = optional(set(string), [])
    service_endpoint_policy_ids                   = optional(set(string))
    private_endpoint_network_policies             = optional(string, "Enabled")
    private_link_service_network_policies_enabled = optional(bool, true)
    default_outbound_access_enabled               = optional(bool, false)
    delegations = optional(map(object({
      name    = string
      actions = optional(list(string), [])
    })), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for s in values(var.subnets) : length(s.address_prefixes) > 0])
    error_message = "Every subnet must declare at least one address prefix."
  }

  validation {
    condition = alltrue([
      for s in values(var.subnets) :
      contains(["Enabled", "Disabled", "NetworkSecurityGroupEnabled", "RouteTableEnabled"], s.private_endpoint_network_policies)
    ])
    error_message = "private_endpoint_network_policies must be Enabled, Disabled, NetworkSecurityGroupEnabled, or RouteTableEnabled."
  }
}

variable "tags" {
  description = "Tags applied to the VNet. Azure subnets do not carry tags."
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
