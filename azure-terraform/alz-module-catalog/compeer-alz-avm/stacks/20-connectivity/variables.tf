variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "centralus"
}

variable "environment" {
  type = string
}

variable "prefix" {
  type    = string
  default = "cmp"
}

variable "enable_telemetry" {
  type    = bool
  default = true
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "hub_address_space" {
  type = list(string)
}

variable "subnets" {
  type = map(object({
    address_prefixes = list(string)
    route_table_key  = optional(string)
  }))
}

variable "hub_route_tables" {
  description = "Hub route tables keyed by logical name. Subnets attach by setting subnets[*].route_table_key."
  type = map(object({
    bgp_route_propagation_enabled = optional(bool, true)
    routes = optional(map(object({
      name                   = string
      address_prefix         = string
      next_hop_type          = string
      next_hop_in_ip_address = optional(string)
    })), {})
  }))
  default = {}
}

variable "spoke_default_routes" {
  description = "Routes applied to the reusable spoke default route table."
  type = map(object({
    name                   = string
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))
  default = {}
}

variable "enable_private_dns_resolver" {
  type    = bool
  default = false
}

variable "enable_bastion" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "palo_trust_ilb_ip" {
  type = string
}

variable "palo_untrust_ilb_ip" {
  type = string
}

variable "palo_health_probe_port" {
  type    = number
  default = 22
}

variable "palo_trust_backend_addresses" {
  type = map(object({
    name                             = optional(string)
    backend_address_pool_object_name = optional(string)
    ip_address                       = optional(string)
    virtual_network_resource_id      = optional(string)
  }))
  default = {}
}

variable "palo_untrust_backend_addresses" {
  type = map(object({
    name                             = optional(string)
    backend_address_pool_object_name = optional(string)
    ip_address                       = optional(string)
    virtual_network_resource_id      = optional(string)
  }))
  default = {}
}
