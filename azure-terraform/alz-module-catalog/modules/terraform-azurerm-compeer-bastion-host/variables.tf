variable "name" {
  description = "Bastion host name. Changing this forces a new resource."
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
variable "bastion_subnet_id" {
  description = "ID of the caller-owned AzureBastionSubnet."
  type        = string
}
variable "public_ip_id" {
  description = "ID of an externally managed Standard Static Public IP."
  type        = string
}
variable "ip_configuration_name" {
  type    = string
  default = "configuration"
}
variable "sku" {
  description = "Basic, Standard, or Premium."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be Basic, Standard or Premium."
  }
}
variable "copy_paste_enabled" {
  type    = bool
  default = true
}
variable "file_copy_enabled" {
  type    = bool
  default = false
}
variable "ip_connect_enabled" {
  type    = bool
  default = false
}
variable "kerberos_enabled" {
  type    = bool
  default = false
}
variable "session_recording_enabled" {
  type    = bool
  default = false
}
variable "shareable_link_enabled" {
  type    = bool
  default = false
}
variable "tunneling_enabled" {
  type    = bool
  default = true
}
variable "scale_units" {
  description = "Scale units (2-50; Standard/Premium only)."
  type        = number
  default     = 2
}
variable "zones" {
  description = "Availability zones for the host."
  type        = list(string)
  default     = null
}
variable "timeouts" {
  type    = object({ create = optional(string), update = optional(string), read = optional(string), delete = optional(string) })
  default = {}
}
variable "tags" {
  description = "Tags applied to the host."
  type        = map(string)
  default     = {}
}
