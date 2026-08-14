variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "virtual_network_id" { type = string }
variable "inbound_endpoints" {
  type = map(object({
    subnet_id                    = string
    private_ip_allocation_method = optional(string, "Dynamic")
    private_ip_address           = optional(string)
    tags                         = optional(map(string), {})
  }))
  default = {}
}
variable "outbound_endpoints" {
  type = map(object({
    subnet_id = string
    tags      = optional(map(string), {})
  }))
  default = {}
}
variable "forwarding_rulesets" {
  type = map(object({
    outbound_endpoint_keys = list(string)
    tags                   = optional(map(string), {})
  }))
  default = {}
}
variable "forwarding_rules" {
  type = map(object({
    ruleset_key = string
    domain_name = string
    enabled     = optional(bool, true)
    target_dns_servers = list(object({
      ip_address = string
      port       = optional(number, 53)
    }))
  }))
  default = {}
}
variable "forwarding_ruleset_vnet_links" {
  type = map(object({
    ruleset_key        = string
    virtual_network_id = string
    metadata           = optional(map(string))
  }))
  default = {}
}
variable "tags" {
  type    = map(string)
  default = {}
}
