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
  default = {}

  validation {
    condition = alltrue([
      for route_server in values(var.route_servers) :
      length(trimspace(route_server.name)) > 0 &&
      length(trimspace(route_server.resource_group_name)) > 0 &&
      length(trimspace(route_server.location)) > 0 &&
      length(trimspace(route_server.public_ip_address_id)) > 0
    ])
    error_message = "Each route server must have non-empty name, resource_group_name, location, and public_ip_address_id values."
  }

  validation {
    condition = alltrue([
      for route_server in values(var.route_servers) :
      can(regex("(?i)/subnets/RouteServerSubnet$", route_server.subnet_id))
    ])
    error_message = "Each route server subnet_id must reference a subnet named RouteServerSubnet."
  }

  validation {
    condition = alltrue(flatten([
      for route_server in values(var.route_servers) : [
        for connection in values(try(route_server.bgp_connections, {})) :
        connection.peer_asn > 0 && connection.peer_asn <= 4294967295
      ]
    ]))
    error_message = "Each BGP connection peer_asn must be between 1 and 4294967295."
  }

  validation {
    condition = alltrue(flatten([
      for route_server in values(var.route_servers) : [
        for connection in values(try(route_server.bgp_connections, {})) :
        can(cidrhost("${connection.peer_ip}/32", 0))
      ]
    ]))
    error_message = "Each BGP connection peer_ip must be a valid IPv4 address."
  }
}
