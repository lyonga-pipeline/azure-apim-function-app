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
  description = "Azure tenant id. Kept as a compatibility input for existing callers."
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
    bgp_enabled   = optional(bool)
    enable_bgp    = optional(bool)
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
