variable "resource_group_name" {
  description = "Default resource group for zones and links. Overridable per zone / per link."
  type        = string
}

variable "zones" {
  description = <<-EOT
    Private DNS zones keyed by zone name (the map key is the Azure zone name, e.g.
    "privatelink.vaultcore.azure.net"). Adding or removing a key affects only that
    zone. Each zone may declare its own VNet links keyed by a stable logical key.
  EOT
  type = map(object({
    resource_group_name = optional(string)
    tags                = optional(map(string), {})
    soa_record = optional(object({
      email        = string
      expire_time  = optional(number)
      minimum_ttl  = optional(number)
      refresh_time = optional(number)
      retry_time   = optional(number)
      ttl          = optional(number)
      tags         = optional(map(string))
    }))
    vnet_links = optional(map(object({
      virtual_network_id   = string
      name                 = optional(string)
      resource_group_name  = optional(string)
      registration_enabled = optional(bool, false)
      tags                 = optional(map(string), {})
    })), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for name in keys(var.zones) :
      can(regex("^[A-Za-z0-9][A-Za-z0-9.-]+[A-Za-z0-9]$", name))
    ])
    error_message = "Every zones key must be a valid DNS zone name."
  }
}

variable "tags" {
  description = "Tags merged onto every zone and link."
  type        = map(string)
  default     = {}
}
