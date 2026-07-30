variable "name" {
  type = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{3,48}[a-zA-Z0-9]$", var.name)) && !can(regex("--", var.name))
    error_message = "name must be 5-50 characters, start and end with a letter or number, and not contain consecutive hyphens."
  }
}

variable "resource_group_name" { type = string }
variable "location" { type = string }

variable "sku" {
  type    = string
  default = "standard"

  validation {
    condition     = contains(["free", "standard"], lower(var.sku))
    error_message = "sku must be free or standard."
  }
}

variable "local_auth_enabled" {
  type    = bool
  default = false
}

variable "public_network_access_enabled" {
  type    = bool
  default = false
}

variable "purge_protection_enabled" {
  type    = bool
  default = true
}

variable "soft_delete_retention_days" {
  type    = number
  default = 7

  validation {
    condition     = var.soft_delete_retention_days >= 1 && var.soft_delete_retention_days <= 7
    error_message = "soft_delete_retention_days must be between 1 and 7."
  }
}

variable "identity" {
  type = object({
    type         = string
    identity_ids = optional(list(string), [])
  })
  default = {
    type         = "SystemAssigned"
    identity_ids = []
  }

  validation {
    condition = var.identity == null || contains([
      "SystemAssigned",
      "UserAssigned",
      "SystemAssigned, UserAssigned"
    ], var.identity.type)
    error_message = "identity.type must be SystemAssigned, UserAssigned, or 'SystemAssigned, UserAssigned'."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}
