variable "tenant_id" {
  type        = string
  description = "Azure tenant ID for the hub and spoke subscriptions."
}

variable "hub_subscription_id" {
  type        = string
  description = "Subscription ID that contains the hub VNet and shared Private DNS zones."
}

variable "spoke_subscription_id" {
  type        = string
  description = "Subscription ID that contains the workload spoke VNet."
}

variable "hub_resource_group_name" {
  type        = string
  description = "Resource group name that contains the hub VNet."
}

variable "hub_virtual_network_name" {
  type        = string
  description = "Hub virtual network name."
}

variable "hub_virtual_network_id" {
  type        = string
  description = "Hub virtual network resource ID."
}

variable "spoke_resource_group_name" {
  type        = string
  description = "Resource group name that contains the spoke VNet."
}

variable "spoke_virtual_network_name" {
  type        = string
  description = "Spoke virtual network name."
}

variable "spoke_virtual_network_id" {
  type        = string
  description = "Spoke virtual network resource ID."
}

variable "peering_name_prefix" {
  type        = string
  description = "Stable name prefix for the two peering resources."
}

variable "hub_to_spoke" {
  type = object({
    allow_forwarded_traffic      = optional(bool, true)
    allow_gateway_transit        = optional(bool, false)
    use_remote_gateways          = optional(bool, false)
    allow_virtual_network_access = optional(bool, true)
  })
  description = "Hub-to-spoke peering flags. Enable allow_gateway_transit only when the hub owns the gateway."
  default     = {}
}

variable "spoke_to_hub" {
  type = object({
    allow_forwarded_traffic      = optional(bool, true)
    allow_gateway_transit        = optional(bool, false)
    use_remote_gateways          = optional(bool, false)
    allow_virtual_network_access = optional(bool, true)
  })
  description = "Spoke-to-hub peering flags. Enable use_remote_gateways only when the hub peering has gateway transit enabled."
  default     = {}
}

variable "private_dns_zone_resource_group_name" {
  type        = string
  description = "Default resource group name for shared Private DNS zones."
  default     = null
}

variable "private_dns_zones" {
  type = map(object({
    name                  = string
    resource_group_name   = optional(string)
    registration_enabled  = optional(bool, false)
    link_name             = optional(string)
    link_to_spoke_enabled = optional(bool, true)
  }))
  description = "Shared Private DNS zones to link to the spoke VNet. Values usually come from platform-connectivity outputs."
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Tags for Private DNS VNet links."
  default     = {}
}
