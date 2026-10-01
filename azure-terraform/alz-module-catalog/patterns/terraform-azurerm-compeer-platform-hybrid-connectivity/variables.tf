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

variable "route_server_public_ips" {
  type = map(object({
    name              = optional(string)
    allocation_method = optional(string, "Static")
    sku               = optional(string, "Standard")
    sku_tier          = optional(string, "Regional")
    zones             = optional(list(string), [])
  }))
  default     = {}
  description = "Public IPs used by Azure Route Server instances."
}

variable "route_servers" {
  type = map(object({
    name                             = optional(string)
    sku                              = optional(string, "Standard")
    subnet_id                        = string
    public_ip_key                    = optional(string)
    public_ip_address_id             = optional(string)
    branch_to_branch_traffic_enabled = optional(bool, true)
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
    bgp_connections = optional(map(object({
      name                 = string
      peer_asn             = number
      peer_ip              = string
      ipv4_route_server_id = optional(string)
      timeouts = optional(object({
        create = optional(string)
        read   = optional(string)
        delete = optional(string)
      }), {})
    })), {})
  }))
  default     = {}
  description = "Azure Route Server instances. Use public_ip_key to consume route_server_public_ips, or public_ip_address_id to bind an externally-owned PIP."

  validation {
    condition = alltrue([
      for route_server in values(var.route_servers) :
      (
        (try(trimspace(route_server.public_ip_key), "") != "" ? 1 : 0) +
        (try(trimspace(route_server.public_ip_address_id), "") != "" ? 1 : 0)
      ) == 1
    ])
    error_message = "Each route_servers entry must set exactly one of public_ip_key or public_ip_address_id."
  }
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

# Placement decision (resource-placement sheet, security-mg /
# platform-cus-prod-keyvault-rg): VPN certificates live in the shared
# platform Key Vault (platform-cus-prod-vault, owned by
# platform-identity-security / the security subscription), not in a
# dedicated vault of this pattern's own. This variable used to also create
# that vault directly (network engineer's original request); it now only
# grants vpn_certificate_identity access to an externally-owned vault ID -
# key_vault_id is the workspace-resolved ID of that shared vault (read via
# tfe_outputs from platform-identity-security).
variable "vpn_certificate_key_vault" {
  type = object({
    enabled      = optional(bool, false)
    key_vault_id = optional(string)
  })
  default     = {}
  description = "Grants vpn_certificate_identity Certificates/Secrets User access to an externally-owned Key Vault (key_vault_id) for VPN gateway certificate management (network engineer request). Does not create a vault - see the shared platform-cus-prod-vault owned by platform-identity-security. key_vault_id is not tfvars-settable in the real workspace - it's auto-resolved from platform-identity-security's published output, so enabled = true with that workspace not yet deployed (key_vault_id still null) is a graceful no-op here, not a validation error - the same pattern as every other optional cross-workspace dependency in this catalog (e.g. hub_connection)."
}

variable "vpn_certificate_identity" {
  type = object({
    name = optional(string)
  })
  default     = {}
  description = "Name override for the user-assigned managed identity granted access to vpn_certificate_key_vault. Defaults to a generated name."
}
