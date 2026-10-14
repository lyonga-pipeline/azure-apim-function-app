variable "hub_virtual_network_id" {
  description = "Approved hub VNet ARM ID; names/RG are derived from the same ID."
  type        = string
}
variable "spoke_virtual_network_id" {
  description = "Approved spoke VNet ARM ID; this pattern never creates a VNet."
  type        = string
}
variable "hub_subscription_id" {
  type = string
}
variable "spoke_subscription_id" {
  type = string
}
variable "tenant_id" {
  description = "Optional explicit tenant assertion; providers must always use the same tenant."
  type        = string
  default     = null
}
variable "private_dns_subscription_id" {
  description = "Actual DNS subscription; null uses the hub subscription."
  type        = string
  default     = null
}
variable "peering_name_prefix" {
  type    = string
  default = "hub-spoke"
}
variable "peering_names" {
  type    = object({ hub_to_spoke = optional(string), spoke_to_hub = optional(string) })
  default = {}
}
variable "hub_to_spoke" {
  type = object({
    allow_virtual_network_access = optional(bool, true)
    allow_forwarded_traffic      = optional(bool, true)
    allow_gateway_transit        = optional(bool, false)
    use_remote_gateways          = optional(bool, false)
  })
  default = {}
}
variable "spoke_to_hub" {
  type = object({
    allow_virtual_network_access = optional(bool, true)
    allow_forwarded_traffic      = optional(bool, true)
    allow_gateway_transit        = optional(bool, false)
    use_remote_gateways          = optional(bool, false)
  })
  default = {}
}
variable "private_dns_zones" {
  description = "Optional existing zones for a central attachment state. Pass {} when the parent blueprint owns DNS links. No zones are created."
  type = map(object({
    name                 = string
    resource_group_name  = string
    link_name            = optional(string)
    registration_enabled = optional(bool, false)
  }))
  default = {}
}
variable "tags" {
  type    = map(string)
  default = {}
}
