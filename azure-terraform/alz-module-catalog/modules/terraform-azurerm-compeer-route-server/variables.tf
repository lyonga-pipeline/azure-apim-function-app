variable "route_servers" {
  description = "Azure Route Servers keyed by logical name."
  type = map(object({
    name                             = string
    resource_group_name              = string
    location                         = string
    sku                              = optional(string, "Standard")
    subnet_id                        = string
    public_ip_address_id             = string
    branch_to_branch_traffic_enabled = optional(bool, true)
    tags                             = optional(map(string), {})
    bgp_connections = optional(map(object({
      name                 = string
      peer_asn             = number
      peer_ip              = string
      ipv4_route_server_id = optional(string)
    })), {})
  }))
  default = {}
}
