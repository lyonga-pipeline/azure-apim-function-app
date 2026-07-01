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
    application         = string
    business_owner      = string
    source_repo         = string
    terraform_workspace = string
    recovery_tier       = string
    cost_center         = string
    data_classification = string
    compliance_boundary = string
    additional_tags     = optional(map(string), {})
  })
}

variable "resource_group" {
  type = object({
    name = string
  })
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
