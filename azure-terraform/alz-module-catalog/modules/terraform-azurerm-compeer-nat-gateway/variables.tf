variable "name" {
  description = "NAT gateway name. Changing this forces a new resource."
  type        = string
}
variable "location" {
  description = "Azure region. Changing this forces a new resource."
  type        = string
}
variable "resource_group_name" {
  description = "Resource group. Changing this forces a new resource."
  type        = string
}
variable "sku_name" {
  description = "SKU name (Standard)."
  type        = string
  default     = "Standard"
}
variable "idle_timeout_in_minutes" {
  description = "Idle timeout in minutes (4-120)."
  type        = number
  default     = 4

  validation {
    condition     = var.idle_timeout_in_minutes >= 4 && var.idle_timeout_in_minutes <= 120
    error_message = "idle_timeout_in_minutes must be between 4 and 120."
  }
}
variable "zones" {
  description = "Availability zone(s). A NAT gateway is zonal, not zone-redundant."
  type        = list(string)
  default     = null
}
variable "tags" {
  description = "Tags applied to the NAT gateway."
  type        = map(string)
  default     = {}
}
