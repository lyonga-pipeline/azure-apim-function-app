variable "name" {
  description = "Public IP name. Changing this forces a new resource."
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

variable "allocation_method" {
  description = "Static or Dynamic. Standard SKU requires Static."
  type        = string
  default     = "Static"

  validation {
    condition     = contains(["Static", "Dynamic"], var.allocation_method)
    error_message = "allocation_method must be Static or Dynamic."
  }
}

variable "sku" {
  description = "Basic or Standard."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard"], var.sku)
    error_message = "sku must be Basic or Standard."
  }
}

variable "sku_tier" {
  description = "Regional or Global."
  type        = string
  default     = "Regional"
}

variable "ip_version" {
  description = "IPv4 or IPv6."
  type        = string
  default     = "IPv4"
}

variable "edge_zone" {
  type    = string
  default = null
}

variable "domain_name_label" {
  type    = string
  default = null
}

variable "domain_name_label_scope" {
  type    = string
  default = null
}

variable "idle_timeout_in_minutes" {
  description = "TCP idle timeout (4-30)."
  type        = number
  default     = 4
}

variable "public_ip_prefix_id" {
  type    = string
  default = null
}

variable "reverse_fqdn" {
  type    = string
  default = null
}

variable "ddos_protection_mode" {
  description = "Disabled, Enabled, or VirtualNetworkInherited."
  type        = string
  default     = null
}

variable "ddos_protection_plan_id" {
  type    = string
  default = null
}

variable "ip_tags" {
  type    = map(string)
  default = {}
}

variable "zones" {
  description = "Availability zones for a zone-redundant Standard IP."
  type        = list(string)
  default     = []
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
  description = "Tags applied to the public IP."
  type        = map(string)
  default     = {}
}
