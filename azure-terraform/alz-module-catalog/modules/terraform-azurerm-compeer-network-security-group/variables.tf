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
  description = "List of objects representing security rules, as defined below."
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
}

variable "subnet_id" {
  description = "The ID of the Subnet. Changing this forces a new resource to be created."
  type        = string
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = {}
}