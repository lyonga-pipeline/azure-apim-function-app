variable "name" {
  description = "Resource name. Changing this forces a new resource."
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "name must be non-empty."
  }
}
variable "resource_group_name" {
  description = "Resource group. Changing this forces a new resource."
  type        = string

  validation {
    condition     = length(trimspace(var.resource_group_name)) > 0
    error_message = "resource_group_name must be non-empty."
  }
}
variable "location" {
  description = "Azure region. Changing this forces a new resource."
  type        = string

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "location must be non-empty."
  }
}
variable "service_provider_name" {
  type = string

  validation {
    condition     = length(trimspace(var.service_provider_name)) > 0
    error_message = "service_provider_name must be non-empty."
  }
}
variable "peering_location" {
  type = string

  validation {
    condition     = length(trimspace(var.peering_location)) > 0
    error_message = "peering_location must be non-empty."
  }
}
variable "bandwidth_in_mbps" {
  type = number

  validation {
    condition     = var.bandwidth_in_mbps > 0
    error_message = "bandwidth_in_mbps must be greater than zero."
  }
}
variable "allow_classic_operations" {
  type    = bool
  default = false
}
variable "sku" {
  type = object({
    tier   = string
    family = string
  })
  default = {
    tier   = "Standard"
    family = "MeteredData"
  }

  validation {
    condition     = contains(["Basic", "Local", "Standard", "Premium"], var.sku.tier)
    error_message = "sku.tier must be Basic, Local, Standard, or Premium."
  }

  validation {
    condition     = contains(["MeteredData", "UnlimitedData"], var.sku.family)
    error_message = "sku.family must be MeteredData or UnlimitedData."
  }
}
variable "tags" {
  description = "Tags applied to the resource."
  type        = map(string)
  default     = {}
}
