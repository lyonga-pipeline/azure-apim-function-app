variable "name" {
  description = "Route table name. Changing this forces a new resource."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group. Changing this forces a new resource."
  type        = string
}

variable "location" {
  description = "Azure region. Changing this forces a new resource."
  type        = string
}

variable "bgp_route_propagation_enabled" {
  description = "Whether BGP-learned routes propagate into this table."
  type        = bool
  default     = true
}

variable "routes" {
  description = "Routes keyed by route name (the map key). Adding/removing a key affects only that route."
  type = map(object({
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([for r in values(var.routes) : contains(
      ["VirtualNetworkGateway", "VnetLocal", "Internet", "VirtualAppliance", "None"], r.next_hop_type
    )])
    error_message = "route next_hop_type must be one of VirtualNetworkGateway, VnetLocal, Internet, VirtualAppliance, None."
  }

  validation {
    condition = alltrue([for r in values(var.routes) :
      (r.next_hop_type == "VirtualAppliance") == (try(r.next_hop_in_ip_address, null) != null)
    ])
    error_message = "next_hop_in_ip_address is required iff next_hop_type is VirtualAppliance."
  }
}

variable "tags" {
  description = "Tags applied to the route table."
  type        = map(string)
  default     = {}
}
