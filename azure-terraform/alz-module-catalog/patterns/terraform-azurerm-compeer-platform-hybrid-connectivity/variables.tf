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

variable "tenant_id" {
  type        = string
  description = "Azure tenant id. Leave null to use the tenant from the active Azure credentials (the keyvault module defaults it internally via data.azurerm_client_config.current)."
  default     = null
}

variable "naming" {
  description = "Root identity for the naming module. Component 'hybrid'. A `name` on a resource block still wins."
  type = object({
    region               = optional(string)
    environment          = optional(string)
    scope                = optional(string, "platform")
    component            = optional(string, "hybrid")
    domain               = optional(string)
    appcode              = optional(string)
    abbreviation         = optional(string)
    key_vault_name_token = optional(string, "vault")
    storage_uniqueness   = optional(string, "")
  })
  default = {}
}


variable "platform_tags" {
  type = object({
    application           = optional(string)
    appcode               = optional(string)
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
    time_bound_exception  = optional(bool, false)
    additional_tags       = optional(map(string), {})
  })
  default = {}
}

variable "resource_group" {
  type = object({
    name = optional(string)
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
    name              = optional(string)
    allocation_method = optional(string, "Static")
    sku               = optional(string, "Standard")
    sku_tier          = optional(string, "Regional")
    zones             = optional(list(string), [])
  }))
  default = {}
}

variable "expressroute_gateway" {
  type = object({
    name          = optional(string)
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
    name              = optional(string)
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
    name          = optional(string)
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

variable "vpn_certificate_key_vault" {
  type = object({
    enabled                    = optional(bool, false)
    name                       = optional(string)
    sku_name                   = optional(string, "premium")
    purge_protection_enabled   = optional(bool, true)
    soft_delete_retention_days = optional(number, 90)
    network = optional(object({
      mode               = optional(string, "private") # private | selected
      allowed_ip_ranges  = optional(list(string), [])
      allowed_subnet_ids = optional(list(string), [])
    }), {})
    private_endpoint = optional(object({
      name                 = string
      subnet_id            = string
      private_dns_zone_ids = optional(list(string), [])
    }))
  })
  default     = {}
  description = "Optional private Key Vault for VPN gateway certificate management (network engineer request: cert authentication needs somewhere to live). Private by default (network_acls Deny + a private endpoint) - set network.mode = \"selected\" only with an approved exception."
}

variable "vpn_certificate_identity" {
  type = object({
    name = optional(string)
  })
  default     = {}
  description = "Name override for the user-assigned managed identity granted access to vpn_certificate_key_vault. Defaults to a generated name."
}
