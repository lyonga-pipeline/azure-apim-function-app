variable "name" {
  description = "Resource name. Changing this forces a new resource."
  type        = string

  validation {
    # Microsoft.Network/connections naming rule: 1-80 chars, alphanumerics/
    # underscores/periods/hyphens, start alphanumeric, end alphanumeric or
    # underscore (Azure resource-name-rules reference).
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
    condition     = contains(["ExpressRoute", "IPsec", "Vnet2Vnet"], var.type)
    error_message = "type must be ExpressRoute, IPsec, or Vnet2Vnet."
  }
}
variable "virtual_network_gateway_id" {
  description = "ID of the VPN/ExpressRoute gateway."
  type        = string
}
variable "express_route_circuit_id" {
  type    = string
  default = null
}
variable "local_network_gateway_id" {
  type    = string
  default = null
}
variable "peer_virtual_network_gateway_id" {
  type    = string
  default = null
}
variable "authorization_key" {
  type      = string
  default   = null
  sensitive = true
}
variable "shared_key" {
  type      = string
  default   = null
  sensitive = true
}
variable "routing_weight" {
  type    = number
  default = 0

  validation {
    condition     = var.routing_weight >= 0
    error_message = "routing_weight must be zero or greater."
  }
}
variable "connection_mode" {
  type    = string
  default = null

  validation {
    condition     = var.connection_mode == null ? true : contains(["Default", "InitiatorOnly", "ResponderOnly"], var.connection_mode)
    error_message = "connection_mode must be Default, InitiatorOnly, or ResponderOnly when set."
  }
}
variable "connection_protocol" {
  type    = string
  default = null

  validation {
    condition     = var.connection_protocol == null ? true : contains(["IKEv1", "IKEv2"], var.connection_protocol)
    error_message = "connection_protocol must be IKEv1 or IKEv2 when set."
  }
}
variable "dpd_timeout_seconds" {
  type    = number
  default = null
}
variable "bgp_enabled" {
  description = "Whether BGP is enabled on the connection. Preferred over deprecated enable_bgp."
  type        = bool
  default     = null
}
variable "enable_bgp" {
  description = "Deprecated compatibility input. Use bgp_enabled for AzureRM v4+."
  type        = bool
  default     = null
}
variable "express_route_gateway_bypass" {
  type    = bool
  default = null
}
variable "use_policy_based_traffic_selectors" {
  type    = bool
  default = null
}
variable "egress_nat_rule_ids" {
  type    = list(string)
  default = null
}
variable "ingress_nat_rule_ids" {
  type    = list(string)
  default = null
}
variable "local_azure_ip_address_enabled" {
  type    = bool
  default = null
}
variable "private_link_fast_path_enabled" {
  type    = bool
  default = null
}
variable "custom_bgp_addresses" {
  type = object({
    primary   = string
    secondary = optional(string)
  })
  default = null
}
variable "ipsec_policy" {
  type = object({
    dh_group         = string
    ike_encryption   = string
    ike_integrity    = string
    ipsec_encryption = string
    ipsec_integrity  = string
    pfs_group        = string
    sa_datasize      = optional(number)
    sa_lifetime      = optional(number)
  })
  default = null

  # Enums and minimums are azurerm_virtual_network_gateway_connection's own
  # documented values; a typo otherwise only fails at apply.
  validation {
    condition     = var.ipsec_policy == null ? true : contains(["DHGroup1", "DHGroup14", "DHGroup2", "DHGroup2048", "DHGroup24", "ECP256", "ECP384", "None"], var.ipsec_policy.dh_group)
    error_message = "ipsec_policy.dh_group must be one of DHGroup1, DHGroup14, DHGroup2, DHGroup2048, DHGroup24, ECP256, ECP384, None."
  }
  validation {
    condition     = var.ipsec_policy == null ? true : contains(["AES128", "AES192", "AES256", "DES", "DES3", "GCMAES128", "GCMAES256"], var.ipsec_policy.ike_encryption)
    error_message = "ipsec_policy.ike_encryption must be one of AES128, AES192, AES256, DES, DES3, GCMAES128, GCMAES256."
  }
  validation {
    condition     = var.ipsec_policy == null ? true : contains(["GCMAES128", "GCMAES256", "MD5", "SHA1", "SHA256", "SHA384"], var.ipsec_policy.ike_integrity)
    error_message = "ipsec_policy.ike_integrity must be one of GCMAES128, GCMAES256, MD5, SHA1, SHA256, SHA384."
  }
  validation {
    condition     = var.ipsec_policy == null ? true : contains(["AES128", "AES192", "AES256", "DES", "DES3", "GCMAES128", "GCMAES192", "GCMAES256", "None"], var.ipsec_policy.ipsec_encryption)
    error_message = "ipsec_policy.ipsec_encryption must be one of AES128, AES192, AES256, DES, DES3, GCMAES128, GCMAES192, GCMAES256, None."
  }
  validation {
    condition     = var.ipsec_policy == null ? true : contains(["GCMAES128", "GCMAES192", "GCMAES256", "MD5", "SHA1", "SHA256"], var.ipsec_policy.ipsec_integrity)
    error_message = "ipsec_policy.ipsec_integrity must be one of GCMAES128, GCMAES192, GCMAES256, MD5, SHA1, SHA256."
  }
  validation {
    condition     = var.ipsec_policy == null ? true : contains(["ECP256", "ECP384", "PFS1", "PFS14", "PFS2", "PFS2048", "PFS24", "PFSMM", "None"], var.ipsec_policy.pfs_group)
    error_message = "ipsec_policy.pfs_group must be one of ECP256, ECP384, PFS1, PFS14, PFS2, PFS2048, PFS24, PFSMM, None."
  }
  validation {
    condition     = var.ipsec_policy == null ? true : (var.ipsec_policy.sa_datasize == null ? true : var.ipsec_policy.sa_datasize >= 1024)
    error_message = "ipsec_policy.sa_datasize must be at least 1024 (KB) when set."
  }
  validation {
    condition     = var.ipsec_policy == null ? true : (var.ipsec_policy.sa_lifetime == null ? true : var.ipsec_policy.sa_lifetime >= 300)
    error_message = "ipsec_policy.sa_lifetime must be at least 300 (seconds) when set."
  }
}
variable "traffic_selector_policies" {
  type = map(object({
    local_address_cidrs  = list(string)
    remote_address_cidrs = list(string)
  }))
  default = {}
}
variable "timeouts" {
  type = object({
    create = optional(string)
    update = optional(string)
    read   = optional(string)
    delete = optional(string)
  })
  default = {}
}
variable "tags" {
  description = "Tags applied to the resource."
  type        = map(string)
  default     = {}
}
