variable "subscription_id" {
  type        = string
  description = "Platform connectivity subscription id."
}

variable "location" {
  type        = string
  description = "Azure region for hybrid connectivity resources."
}

variable "environment" {
  type        = string
  description = "Environment key, such as np or prod."
}

variable "platform_tags" {
  type = object({
    application           = optional(string)
    owner                 = optional(string)
    source_repo           = optional(string)
    created_on            = optional(string)
    criticality_tier      = optional(string)
    data_classification   = optional(string)
    lifecycle_state       = optional(string)
    cost_center           = optional(string)
    gl_category           = optional(string)
    application_component = optional(string)
    modified_on           = optional(string)
    created_by            = optional(string)
    dr_tier               = optional(string)
    expiration_date       = optional(string)
    additional_tags       = optional(map(string), {})
  })
  default = {}
}

variable "resource_group" {
  type = object({
    name = string
  })
}

variable "expressroute_posture" {
  type = object({
    enabled                   = optional(bool, false)
    onpremises_required       = optional(bool, true)
    provider_design_reference = optional(string)
    bgp_and_routing_approved  = optional(bool, false)
    cutover_window_approved   = optional(bool, false)
    notes                     = optional(string)
  })
  description = "No-cost ExpressRoute posture contract. When enabled, this root requires approved provider, BGP/routing, gateway, and connection inputs."
  default     = {}
}

variable "expressroute_circuits" {
  type = map(object({
    name                     = string
    service_provider_name    = string
    peering_location         = string
    bandwidth_in_mbps        = number
    allow_classic_operations = optional(bool, false)
    sku = optional(object({
      tier   = string
      family = string
      }), {
      tier   = "Standard"
      family = "MeteredData"
    })
  }))
  default     = {}
  description = "ExpressRoute circuits. Service provider details should come from approved carrier design inputs."
}

variable "gateway_public_ips" {
  type = map(object({
    name              = string
    allocation_method = optional(string, "Static")
    sku               = optional(string, "Standard")
    sku_tier          = optional(string, "Regional")
    zones             = optional(list(string), [])
  }))
  default = {}
}

variable "expressroute_gateway" {
  type = object({
    name          = string
    sku           = optional(string, "ErGw1AZ")
    active_active = optional(bool, false)
    enable_bgp    = optional(bool, true)
    ip_configurations = map(object({
      public_ip_key                 = string
      gateway_subnet_id             = string
      private_ip_address_allocation = optional(string, "Dynamic")
    }))
  })
  default     = null
  description = "ExpressRoute virtual network gateway. Requires a GatewaySubnet in the hub VNet."
}

variable "expressroute_connections" {
  type = map(object({
    name              = string
    circuit_key       = string
    authorization_key = optional(string)
    routing_weight    = optional(number, 0)
  }))
  default = {}
}

variable "vpn_posture" {
  type = object({
    enabled                      = optional(bool, false)
    backup_required              = optional(bool, true)
    design_reference             = optional(string)
    bgp_and_routing_approved     = optional(bool, false)
    shared_key_handling_approved = optional(bool, false)
    failover_test_approved       = optional(bool, false)
    notes                        = optional(string)
  })
  description = "No-cost VPN backup posture contract. When enabled, this root requires approved VPN gateway, local network gateway, and IPsec connection inputs."
  default     = {}
}

variable "vpn_gateway_public_ips" {
  type = map(object({
    name              = string
    allocation_method = optional(string, "Static")
    sku               = optional(string, "Standard")
    sku_tier          = optional(string, "Regional")
    zones             = optional(list(string), [])
  }))
  default     = {}
  description = "Public IPs used by the VPN virtual network gateway."
}

variable "vpn_gateway" {
  type = object({
    name          = string
    sku           = optional(string, "VpnGw1AZ")
    vpn_type      = optional(string, "RouteBased")
    active_active = optional(bool, false)
    enable_bgp    = optional(bool, false)
    generation    = optional(string)
    ip_configurations = map(object({
      public_ip_key                 = string
      gateway_subnet_id             = string
      private_ip_address_allocation = optional(string, "Dynamic")
    }))
  })
  default     = null
  description = "VPN virtual network gateway. Requires a GatewaySubnet in the hub VNet."
}

variable "local_network_gateways" {
  type = map(object({
    name            = string
    gateway_address = string
    address_space   = list(string)
    bgp_settings = optional(object({
      asn                 = number
      bgp_peering_address = string
      peer_weight         = optional(number)
    }))
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
  }))
  default     = {}
  description = "On-premises VPN peer definitions represented as Azure local network gateways."
}

variable "vpn_connections" {
  type = map(object({
    name                               = string
    local_network_gateway_key          = string
    shared_key                         = optional(string)
    routing_weight                     = optional(number, 0)
    connection_mode                    = optional(string)
    connection_protocol                = optional(string)
    dpd_timeout_seconds                = optional(number)
    enable_bgp                         = optional(bool)
    use_policy_based_traffic_selectors = optional(bool)
    local_azure_ip_address_enabled     = optional(bool)
    private_link_fast_path_enabled     = optional(bool)
    egress_nat_rule_ids                = optional(list(string))
    ingress_nat_rule_ids               = optional(list(string))
    custom_bgp_addresses = optional(object({
      primary   = string
      secondary = optional(string)
    }))
    ipsec_policy = optional(object({
      dh_group         = string
      ike_encryption   = string
      ike_integrity    = string
      ipsec_encryption = string
      ipsec_integrity  = string
      pfs_group        = string
      sa_datasize      = optional(number)
      sa_lifetime      = optional(number)
    }))
    traffic_selector_policies = optional(map(object({
      local_address_cidrs  = list(string)
      remote_address_cidrs = list(string)
    })), {})
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }), {})
  }))
  default     = {}
  description = "IPsec VPN backup gateway connections. Shared keys should be injected from HCP sensitive variables or an approved secret store."
}
