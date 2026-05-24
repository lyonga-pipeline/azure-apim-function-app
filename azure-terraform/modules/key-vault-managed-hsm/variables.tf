variable "name" {
  type = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$", var.name)) && !can(regex("--", var.name))
    error_message = "Managed HSM names must be 3-24 characters, start with a letter, end with a letter or number, and not contain consecutive hyphens."
  }
}
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tenant_id" { type = string }
variable "sku_name" {
  type    = string
  default = "Standard_B1"

  validation {
    condition     = var.sku_name == "Standard_B1"
    error_message = "sku_name must be Standard_B1 for Managed HSM."
  }
}
variable "purge_protection_enabled" {
  type    = bool
  default = true
}
variable "soft_delete_retention_days" {
  type    = number
  default = 90

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "soft_delete_retention_days must be between 7 and 90."
  }
}
variable "public_network_access_enabled" {
  type    = bool
  default = false
}
variable "admin_object_ids" {
  type = list(string)

  validation {
    condition     = length(var.admin_object_ids) > 0
    error_message = "At least one admin_object_id is required."
  }
}
variable "network_acls" {
  type = object({
    bypass         = optional(string, "None")
    default_action = optional(string, "Deny")
  })
  default = {}

  validation {
    condition     = contains(["AzureServices", "None"], var.network_acls.bypass)
    error_message = "network_acls.bypass must be AzureServices or None."
  }

  validation {
    condition     = contains(["Allow", "Deny"], var.network_acls.default_action)
    error_message = "network_acls.default_action must be Allow or Deny."
  }
}
variable "tags" {
  type    = map(string)
  default = {}
}
