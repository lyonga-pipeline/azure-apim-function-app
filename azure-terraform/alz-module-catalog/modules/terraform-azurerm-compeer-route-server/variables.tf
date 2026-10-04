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
    # try(...) keeps an unresolved (null) value a clean validation failure
    # instead of a trimspace(null) function error.
    condition = alltrue([
      for route_server in values(var.route_servers) :
      try(length(trimspace(route_server.name)) > 0, false) &&
      try(length(trimspace(route_server.resource_group_name)) > 0, false) &&
      try(length(trimspace(route_server.location)) > 0, false) &&
      try(length(trimspace(route_server.public_ip_address_id)) > 0, false)
    ])
    error_message = "Each route server must have non-empty name, resource_group_name, location, and public_ip_address_id values."
  }

  validation {
    # azurerm_route_server documents Standard as the only SKU.
    condition     = alltrue([for route_server in values(var.route_servers) : route_server.sku == "Standard"])
    error_message = "Each route server sku must be Standard (the only SKU azurerm_route_server supports)."
  }

  validation {
    # Azure Route Server FAQ: only one Route Server per virtual network, and
    # it must live in that VNet's RouteServerSubnet - so two route servers
    # can never share a subnet.
    condition     = length(distinct([for route_server in values(var.route_servers) : try(lower(route_server.subnet_id), "")])) == length(var.route_servers)
    error_message = "Each route server must use its own RouteServerSubnet - Azure allows only one Route Server per virtual network."
  }

  validation {
    # Azure Route Server limit: 16 BGP peers per deployment.
    condition     = alltrue([for route_server in values(var.route_servers) : length(try(route_server.bgp_connections, {})) <= 16])
    error_message = "A route server supports at most 16 BGP peers (bgp_connections)."
  }

  validation {
    condition = alltrue([
      for route_server in values(var.route_servers) :
      can(regex("(?i)/subnets/RouteServerSubnet$", route_server.subnet_id))
    ])
    error_message = "Each route server subnet_id must reference a subnet named RouteServerSubnet."
  }

  validation {
    # Azure Route Server FAQ: only 16-bit (2-byte) ASNs are supported, and
    # ASNs reserved by Azure (public 8074, 8075, 12076; private 65515,
    # 65517-65520) or by IANA (23456, 64496-64511, 65535-65551) cannot be
    # used for a peer.
    condition = alltrue(flatten([
      for route_server in values(var.route_servers) : [
        for connection in values(try(route_server.bgp_connections, {})) :
        connection.peer_asn >= 1 && connection.peer_asn <= 65534 &&
        !contains([8074, 8075, 12076, 23456, 65515, 65517, 65518, 65519, 65520], connection.peer_asn) &&
        !(connection.peer_asn >= 64496 && connection.peer_asn <= 64511)
      ]
    ]))
    error_message = "Each BGP connection peer_asn must be a 2-byte ASN (1-65534) that is not reserved by Azure (8074, 8075, 12076, 65515, 65517-65520) or IANA (23456, 64496-64511, 65535)."
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
