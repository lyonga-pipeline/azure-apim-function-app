variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "address_space" { type = list(string) }
variable "dns_servers" {
  type    = list(string)
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
    private_endpoint_network_policies             = optional(string, "Enabled")
    private_link_service_network_policies_enabled = optional(bool, true)
    delegations = optional(map(object({
      name    = string
      actions = optional(list(string), [])
    })), {})
  }))
  default = {}
}
variable "tags" {
  type    = map(string)
  default = {}
}
