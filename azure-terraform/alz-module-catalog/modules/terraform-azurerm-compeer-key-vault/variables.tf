variable "name" {
  description = "Key Vault name (globally unique). Changing this forces a new resource."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$", var.name)) && !can(regex("--", var.name))
    error_message = "Key Vault names must be 3-24 characters, start with a letter, end with a letter or number, and not contain consecutive hyphens."
  }
}
variable "resource_group_name" {
  description = "Resource group the vault is created in. Changing this forces a new resource."
  type        = string
}
variable "location" {
  description = "Azure region. Changing this forces a new resource."
  type        = string
}
variable "tenant_id" {
  description = "Entra ID tenant the vault is bound to."
  type        = string
}
variable "sku_name" {
  description = "standard or premium."
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], lower(var.sku_name))
    error_message = "sku_name must be standard or premium."
  }
}
variable "enabled_for_deployment" {
  description = "Allow Azure VMs to retrieve certificates stored as secrets."
  type        = bool
  default     = false
}
variable "enabled_for_disk_encryption" {
  description = "Allow Azure Disk Encryption to retrieve secrets and unwrap keys."
  type        = bool
  default     = false
}
variable "enabled_for_template_deployment" {
  description = "Allow ARM template deployments to retrieve secrets."
  type        = bool
  default     = false
}
variable "soft_delete_retention_days" {
  description = "Soft-delete retention window in days (7-90)."
  type        = number
  default     = 90
  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "soft_delete_retention_days must be between 7 and 90."
  }
}
variable "purge_protection_enabled" {
  description = "Purge protection. One-way: cannot be disabled once enabled."
  type        = bool
  default     = true
}
variable "public_network_access_enabled" {
  description = "Whether the vault is reachable from public networks. Defaults closed."
  type        = bool
  default     = false
}
variable "rbac_authorization_enabled" {
  description = "Use Azure RBAC authorization. Set false only when this module intentionally manages access policies."
  type        = bool
  default     = true
}
variable "access_policies" {
  description = "Access policies keyed by stable business identifier. Used only when rbac_authorization_enabled = false."
  type = map(object({
    tenant_id               = string
    object_id               = string
    application_id          = optional(string)
    key_permissions         = optional(list(string), [])
    secret_permissions      = optional(list(string), [])
    certificate_permissions = optional(list(string), [])
    storage_permissions     = optional(list(string), [])
  }))
  default = {}
}
variable "network_acls" {
  description = "Network ACLs. null omits the block (no restriction); set an object for deny-by-default."
  type = object({
    bypass                     = optional(string, "None")
    default_action             = optional(string, "Deny")
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  default = null
  validation {
    condition     = var.network_acls == null ? true : contains(["AzureServices", "None"], var.network_acls.bypass)
    error_message = "network_acls.bypass must be AzureServices or None."
  }
  validation {
    condition     = var.network_acls == null ? true : contains(["Allow", "Deny"], var.network_acls.default_action)
    error_message = "network_acls.default_action must be Allow or Deny."
  }
}
variable "contacts" {
  description = "Certificate contacts keyed by a stable logical name."
  type        = map(object({ email = string, name = optional(string), phone = optional(string) }))
  default     = {}
}
variable "tags" {
  description = "Tags applied to the vault."
  type        = map(string)
  default     = {}
}
variable "timeouts" {
  description = "Optional resource operation timeouts."
  type        = object({ create = optional(string), read = optional(string), update = optional(string), delete = optional(string) })
  default     = {}
}
