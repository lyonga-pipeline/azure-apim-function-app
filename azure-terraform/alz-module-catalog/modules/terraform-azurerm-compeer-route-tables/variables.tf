variable "name" {
  description = "Name of the route table. Changing this forces a new resource."
  type        = string
}

variable "location" {
  description = "Azure region the route table is created in."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the route table is created in."
  type        = string
}

variable "bgp_route_propagation_enabled" {
  description = "Whether routes learned by BGP on the associated gateway propagate into this table."
  type        = bool
  default     = true
}

variable "routes" {
  description = <<-EOT
    Routes keyed by route name (the map key is the Azure route name). Adding or
    removing a key affects only that route, never the others.
  EOT
  type = map(object({
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for r in values(var.routes) : contains(
        ["VirtualNetworkGateway", "VnetLocal", "Internet", "VirtualAppliance", "None"],
        r.next_hop_type
      )
    ])
    error_message = "route next_hop_type must be one of VirtualNetworkGateway, VnetLocal, Internet, VirtualAppliance, None."
  }

  validation {
    condition = alltrue([
      for r in values(var.routes) :
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

variable "timeouts" {
  description = "Optional resource operation timeouts."
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = {}
}
