variable "name" {
  description = "Specifies the name of the network security group. Changing this forces a new resource to be created."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the network security group. Changing this forces a new resource to be created."
  type        = string
}

variable "location" {
  description = "Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
  type        = string
}

variable "security_rule" {
  description = "Backward-compatible list of security rules. Prefer security_rules for new consumers so rule identity is keyed by name."
  type = list(object({
    name                                       = string
    description                                = optional(string)
    protocol                                   = optional(string)
    source_port_range                          = optional(string)
    source_port_ranges                         = optional(set(string))
    destination_port_range                     = optional(string)
    destination_port_ranges                    = optional(set(string))
    source_address_prefix                      = optional(string)
    source_address_prefixes                    = optional(set(string))
    source_application_security_group_ids      = optional(set(string))
    destination_address_prefix                 = optional(string)
    destination_address_prefixes               = optional(set(string))
    destination_application_security_group_ids = optional(set(string))
    access                                     = string
    priority                                   = number
    direction                                  = string
  }))
  default = []
}

variable "security_rules" {
  description = "Keyed security rules. Keys should be stable names; each value.name is the Azure NSG rule name."
  type = map(object({
    name                                       = string
    description                                = optional(string)
    protocol                                   = optional(string)
    source_port_range                          = optional(string)
    source_port_ranges                         = optional(set(string))
    destination_port_range                     = optional(string)
    destination_port_ranges                    = optional(set(string))
    source_address_prefix                      = optional(string)
    source_address_prefixes                    = optional(set(string))
    source_application_security_group_ids      = optional(set(string))
    destination_address_prefix                 = optional(string)
    destination_address_prefixes               = optional(set(string))
    destination_application_security_group_ids = optional(set(string))
    access                                     = string
    priority                                   = number
    direction                                  = string
  }))
  default = {}

  validation {
    condition     = alltrue([for r in values(var.security_rules) : r.priority >= 100 && r.priority <= 4096])
    error_message = "security_rules[*].priority must be between 100 and 4096."
  }

  validation {
    condition     = alltrue([for r in values(var.security_rules) : contains(["Allow", "Deny"], r.access) && contains(["Inbound", "Outbound"], r.direction)])
    error_message = "security_rules[*].access must be Allow/Deny and direction Inbound/Outbound."
  }
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = {}
}
