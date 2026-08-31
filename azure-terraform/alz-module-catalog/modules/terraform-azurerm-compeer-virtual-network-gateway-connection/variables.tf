variable "name" {
  description = "Resource name. Changing this forces a new resource."
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
variable "type" {
  type    = string
  default = "ExpressRoute"
}
variable "virtual_network_gateway_id" {
  description = "ID of the VPN/ExpressRoute gateway."
  type        = string
}
variable "express_route_circuit_id" {
  type    = string
  default = null
}
variable "local_network_gateway_id" {
  type    = string
  default = null
}
variable "peer_virtual_network_gateway_id" {
  type    = string
  default = null
}
variable "authorization_key" {
  type    = string
  default = null
}
variable "shared_key" {
  type      = string
  default   = null
  sensitive = true
}
variable "routing_weight" {
  type    = number
  default = 0
}
variable "connection_mode" {
  type    = string
  default = null
}
variable "connection_protocol" {
  type    = string
  default = null
}
variable "dpd_timeout_seconds" {
  type    = number
  default = null
}
variable "enable_bgp" {
  type    = bool
  default = null
}
variable "express_route_gateway_bypass" {
  type    = bool
  default = null
}
variable "use_policy_based_traffic_selectors" {
  type    = bool
  default = null
}
variable "egress_nat_rule_ids" {
  type    = list(string)
  default = null
}
variable "ingress_nat_rule_ids" {
  type    = list(string)
  default = null
}
variable "local_azure_ip_address_enabled" {
  type    = bool
  default = null
}
variable "private_link_fast_path_enabled" {
  type    = bool
  default = null
}
variable "custom_bgp_addresses" {
  type = object({
    primary   = string
    secondary = optional(string)
  })
  default = null
}
variable "ipsec_policy" {
  type = object({
    dh_group         = string
    ike_encryption   = string
    ike_integrity    = string
    ipsec_encryption = string
    ipsec_integrity  = string
    pfs_group        = string
    sa_datasize      = optional(number)
    sa_lifetime      = optional(number)
  })
  default = null
}
variable "traffic_selector_policies" {
  type = map(object({
    local_address_cidrs  = list(string)
    remote_address_cidrs = list(string)
  }))
  default = {}
}
variable "timeouts" {
  type = object({
    create = optional(string)
    update = optional(string)
    read   = optional(string)
    delete = optional(string)
  })
  default = {}
}
variable "tags" {
  description = "Tags applied to the resource."
  type        = map(string)
  default     = {}
}
