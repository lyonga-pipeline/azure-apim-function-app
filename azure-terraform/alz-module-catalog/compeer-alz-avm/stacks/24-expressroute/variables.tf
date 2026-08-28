variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "centralus"
}

variable "resource_group_name" {
  type = string
}

variable "expressroute_circuits" {
  description = "ExpressRoute circuits created in this subscription."
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
    peerings = optional(map(object({
      peering_type                  = string
      vlan_id                       = number
      peer_asn                      = optional(number)
      primary_peer_address_prefix   = optional(string)
      secondary_peer_address_prefix = optional(string)
      shared_key                    = optional(string)
      route_filter_id               = optional(string)
      ipv4_enabled                  = optional(bool, true)
      microsoft_peering_config = optional(object({
        advertised_public_prefixes = list(string)
        advertised_communities     = optional(list(string))
        customer_asn               = optional(number)
        routing_registry_name      = optional(string)
      }))
      ipv6 = optional(object({
        enabled                       = optional(bool, true)
        primary_peer_address_prefix   = string
        secondary_peer_address_prefix = string
        route_filter_id               = optional(string)
        microsoft_peering = optional(object({
          advertised_public_prefixes = optional(list(string))
          advertised_communities     = optional(list(string))
          customer_asn               = optional(number)
          routing_registry_name      = optional(string)
        }))
      }))
    })), {})
    authorizations = optional(map(object({
      name = string
    })), {})
  }))
  default = {}
}

variable "gateway_connections" {
  description = "Gateway connections to created or existing ExpressRoute circuits."
  type = map(object({
    name                       = string
    virtual_network_gateway_id = string
    express_route_circuit_key  = optional(string)
    express_route_circuit_id   = optional(string)
    authorization_key          = optional(string)
    routing_weight             = optional(number, 0)
  }))
  default = {}

  validation {
    condition = alltrue([
      for connection in values(var.gateway_connections) :
      (try(connection.express_route_circuit_key, null) != null) != (try(connection.express_route_circuit_id, null) != null)
    ])
    error_message = "Each gateway connection must set exactly one of express_route_circuit_key or express_route_circuit_id."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}
