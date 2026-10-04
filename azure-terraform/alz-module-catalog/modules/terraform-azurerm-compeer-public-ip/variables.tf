variable "name" {
  description = "Public IP name. Changing this forces a new resource."
  type        = string

  validation {
    # Microsoft.Network/publicIPAddresses naming rule: 1-80 chars,
    # alphanumerics/underscores/periods/hyphens, start with alphanumeric,
    # end with alphanumeric or underscore (Azure resource-name-rules reference).
    condition     = can(regex("^[A-Za-z0-9]([A-Za-z0-9_.-]{0,78}[A-Za-z0-9_])?$", var.name))
    error_message = "name must be 1-80 characters (alphanumerics, underscores, periods, hyphens), start with an alphanumeric, and end with an alphanumeric or underscore."
  }
}

variable "resource_group_name" {
  description = "Resource group. Changing this forces a new resource."
  type        = string

  validation {
    condition     = trimspace(var.resource_group_name) != ""
    error_message = "resource_group_name must not be empty."
  }
}

variable "location" {
  description = "Azure region. Changing this forces a new resource."
  type        = string

  validation {
    condition     = trimspace(var.location) != ""
    error_message = "location must not be empty."
  }
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

  validation {
    condition     = contains(["Regional", "Global"], var.sku_tier)
    error_message = "sku_tier must be Regional or Global."
  }
}

variable "ip_version" {
  description = "IPv4 or IPv6."
  type        = string
  default     = "IPv4"

  validation {
    condition     = contains(["IPv4", "IPv6"], var.ip_version)
    error_message = "ip_version must be IPv4 or IPv6."
  }
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

  validation {
    condition     = var.domain_name_label_scope == null ? true : contains(["TenantReuse", "SubscriptionReuse", "ResourceGroupReuse", "NoReuse"], var.domain_name_label_scope)
    error_message = "domain_name_label_scope must be TenantReuse, SubscriptionReuse, ResourceGroupReuse, or NoReuse."
  }
}

variable "idle_timeout_in_minutes" {
  description = "TCP idle timeout (4-30)."
  type        = number
  default     = 4

  validation {
    condition     = var.idle_timeout_in_minutes >= 4 && var.idle_timeout_in_minutes <= 30
    error_message = "idle_timeout_in_minutes must be between 4 and 30."
  }
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

  validation {
    condition     = var.ddos_protection_mode == null ? true : contains(["Disabled", "Enabled", "VirtualNetworkInherited"], var.ddos_protection_mode)
    error_message = "ddos_protection_mode must be Disabled, Enabled, or VirtualNetworkInherited."
  }
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
