variable "name" {
  description = "VNet name. Changing this forces a new resource."
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
variable "address_space" {
  description = "VNet address space (one or more CIDRs)."
  type        = list(string)

  validation {
    condition     = length(var.address_space) > 0
    error_message = "address_space must contain at least one CIDR."
  }
}
variable "dns_servers" {
  description = "Custom DNS servers. null keeps Azure-provided DNS."
  type        = list(string)
  default     = null
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
  description = "Connection flow timeout in minutes (4-30)."
  type        = number
  default     = null

  validation {
    condition     = var.flow_timeout_in_minutes == null ? true : (var.flow_timeout_in_minutes >= 4 && var.flow_timeout_in_minutes <= 30)
    error_message = "flow_timeout_in_minutes must be between 4 and 30."
  }
}
variable "private_endpoint_vnet_policies" {
  description = "Private Endpoint VNet policy mode (Disabled or Basic)."
  type        = string
  default     = null
}
variable "ddos_protection_plan_id" {
  description = "Externally managed DDoS plan to associate. null = none."
  type        = string
  default     = null
}
variable "enable_ddos_protection_plan" {
  description = "Whether the DDoS association is enabled (only used with ddos_protection_plan_id)."
  type        = bool
  default     = true
}
variable "subnets" {
  description = "Subnets keyed by name. Adding/removing a key never re-creates unrelated subnets."
  type = map(object({
    address_prefixes                              = list(string)
    service_endpoints                             = optional(list(string), [])
    service_endpoint_policy_ids                   = optional(list(string), [])
    default_outbound_access_enabled               = optional(bool)
    private_endpoint_network_policies             = optional(string, "Enabled")
    private_link_service_network_policies_enabled = optional(bool, true)
    sharing_scope                                 = optional(string)
    # Composition hints - not used by this module; a pattern reads them to
    # build subnet <-> route-table / NSG associations from one place.
    route_table_key = optional(string)
    nsg_key         = optional(string)
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

  validation {
    condition     = var.encryption == null ? true : contains(["AllowUnencrypted", "DropUnencrypted"], var.encryption.enforcement)
    error_message = "encryption.enforcement must be AllowUnencrypted or DropUnencrypted."
  }
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
  description = "Tags applied to the VNet."
  type        = map(string)
  default     = {}
}
