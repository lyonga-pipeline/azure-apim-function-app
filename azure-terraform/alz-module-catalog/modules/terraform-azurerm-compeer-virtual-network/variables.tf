variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "address_space" { type = list(string) }
variable "dns_servers" {
  type    = list(string)
  default = null
}
variable "bgp_community" {
  type    = string
  default = null
}
variable "edge_zone" {
  type    = string
  default = null
}
variable "flow_timeout_in_minutes" {
  type    = number
  default = null
}
variable "private_endpoint_vnet_policies" {
  type    = string
  default = null
}
variable "ddos_protection_plan_id" {
  type    = string
  default = null
}
variable "enable_ddos_protection_plan" {
  type    = bool
  default = true
}
variable "subnets" {
  type = map(object({
    address_prefixes                              = list(string)
    service_endpoints                             = optional(list(string), [])
    service_endpoint_policy_ids                   = optional(list(string), [])
    default_outbound_access_enabled               = optional(bool)
    private_endpoint_network_policies             = optional(string, "Enabled")
    private_link_service_network_policies_enabled = optional(bool, true)
    sharing_scope                                 = optional(string)
    delegations = optional(map(object({
      name    = string
      actions = optional(list(string), [])
    })), {})
    ip_address_pool = optional(object({
      id                     = string
      number_of_ip_addresses = string
    }))
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }), {})
  }))
  default = {}
}
variable "encryption" {
  type = object({
    enforcement = string
  })
  default = null
}
variable "ip_address_pools" {
  type = map(object({
    id                     = string
    number_of_ip_addresses = string
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
  type    = map(string)
  default = {}
}
