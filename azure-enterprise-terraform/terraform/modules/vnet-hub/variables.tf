variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "address_space" {
  type = list(string)
}

variable "dns_servers" {
  type    = list(string)
  default = null
}

variable "ddos_protection_plan_id" {
  type    = string
  default = null
}

variable "enable_firewall" {
  type    = bool
  default = false
}

variable "firewall_network_rule_collections" {
  type = list(object({
    name     = string
    priority = number
    action   = string
    rules = list(object({
      name                  = string
      source_addresses      = list(string)
      destination_ports     = list(string)
      destination_addresses = optional(list(string))
      destination_fqdns     = optional(list(string))
      protocols             = list(string)
    }))
  }))
  default = []
}

variable "firewall_policy_name" {
  type    = string
  default = null
}

variable "firewall_policy_rule_collection_group_name" {
  type    = string
  default = "default-network"
}

variable "firewall_policy_rule_collection_group_priority" {
  type    = number
  default = 100
}

variable "firewall_threat_intelligence_mode" {
  type    = string
  default = "Alert"
}

variable "firewall_sku_tier" {
  type    = string
  default = "Standard"
}

variable "enable_nat_gateway" {
  type    = bool
  default = false
}

variable "nat_gateway_name" {
  type    = string
  default = null
}

variable "nat_gateway_subnet_keys" {
  type    = list(string)
  default = ["AzureFirewallSubnet"]
}

variable "nat_gateway_create_public_ip" {
  type    = bool
  default = true
}

variable "nat_gateway_idle_timeout_in_minutes" {
  type    = number
  default = 10
}

variable "nat_gateway_zones" {
  type    = list(string)
  default = []
}

variable "enable_bastion" {
  type    = bool
  default = false
}

variable "bastion_name" {
  type    = string
  default = null
}

variable "bastion_sku" {
  type    = string
  default = "Standard"
}

variable "bastion_copy_paste_enabled" {
  type    = bool
  default = true
}

variable "bastion_file_copy_enabled" {
  type    = bool
  default = false
}

variable "bastion_ip_connect_enabled" {
  type    = bool
  default = false
}

variable "bastion_shareable_link_enabled" {
  type    = bool
  default = false
}

variable "bastion_tunneling_enabled" {
  type    = bool
  default = true
}

variable "bastion_scale_units" {
  type    = number
  default = 2
}

variable "firewall_subnet_cidr" {
  type    = string
  default = "10.0.0.0/26"
}

variable "bastion_subnet_cidr" {
  type    = string
  default = "10.0.0.64/26"
}

variable "shared_services_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "private_endpoints_subnet_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "dns_inbound_subnet_cidr" {
  type    = string
  default = "10.0.3.0/24"
}

variable "dns_outbound_subnet_cidr" {
  type    = string
  default = "10.0.4.0/24"
}

variable "shared_services_nsg_rules" {
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = optional(string, "*")
    destination_port_range     = optional(string, "*")
    source_address_prefix      = optional(string, "*")
    destination_address_prefix = optional(string, "*")
  }))
  default = []
}

variable "subnets" {
  type = map(object({
    address_prefixes                              = list(string)
    service_endpoints                             = optional(list(string), [])
    private_endpoint_network_policies             = optional(string)
    private_endpoint_network_policies_enabled     = optional(bool, true)
    enforce_private_link_service_network_policies = optional(bool, true)
    private_link_service_network_policies_enabled = optional(bool, true)
    route_table_id                                = optional(string)
    nat_gateway_id                                = optional(string)
    nsg_rules = optional(list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = optional(string, "*")
      destination_port_range     = optional(string, "*")
      source_address_prefix      = optional(string, "*")
      destination_address_prefix = optional(string, "*")
    })), [])
    delegations = optional(list(object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    })), [])
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
