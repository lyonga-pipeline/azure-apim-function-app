variable "local_network_gateways" {
  description = "Local network gateways keyed by logical name."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    gateway_address     = string
    address_space       = list(string)
    bgp_settings = optional(object({
      asn                 = number
      bgp_peering_address = string
      peer_weight         = optional(number)
    }))
    tags = optional(map(string), {})
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
  }))
  default = {}
}
