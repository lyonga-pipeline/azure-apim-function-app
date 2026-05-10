variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "rules" {
  type = map(object({
    priority                                   = number
    direction                                  = string
    access                                     = string
    protocol                                   = string
    source_port_range                          = optional(string)
    source_port_ranges                         = optional(list(string))
    destination_port_range                     = optional(string)
    destination_port_ranges                    = optional(list(string))
    source_address_prefix                      = optional(string)
    source_address_prefixes                    = optional(list(string))
    destination_address_prefix                 = optional(string)
    destination_address_prefixes               = optional(list(string))
    source_application_security_group_ids      = optional(list(string))
    destination_application_security_group_ids = optional(list(string))
    description                                = optional(string)
  }))
  default = {}

  validation {
    condition     = length(distinct([for rule in values(var.rules) : rule.priority])) == length(values(var.rules))
    error_message = "Each NSG rule priority must be unique."
  }
}
variable "tags" {
  type    = map(string)
  default = {}
}
