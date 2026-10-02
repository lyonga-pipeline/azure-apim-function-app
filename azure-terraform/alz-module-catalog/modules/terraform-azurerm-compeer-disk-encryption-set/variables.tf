variable "name" {
  description = "Name of the disk encryption set."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_-]{1,80}$", var.name))
    error_message = "name must be 1-80 characters and contain only letters, numbers, underscores, or hyphens."
  }
}

variable "resource_group_name" {
  description = "Resource group name that will contain the disk encryption set."
  type        = string

  validation {
    condition     = trimspace(var.resource_group_name) != ""
    error_message = "resource_group_name must not be empty."
  }
}

variable "location" {
  description = "Azure region for the disk encryption set."
  type        = string

  validation {
    condition     = trimspace(var.location) != ""
    error_message = "location must not be empty."
  }
}

variable "key_vault_key_id" {
  description = "Versioned or version-less Key Vault key ID (from a Standard/Premium vault). Set exactly one of key_vault_key_id or managed_hsm_key_id."
  type        = string
  default     = null

  validation {
    condition     = var.key_vault_key_id == null ? true : trimspace(var.key_vault_key_id) != ""
    error_message = "key_vault_key_id must be null or a non-empty Key Vault key ID."
  }
}

variable "managed_hsm_key_id" {
  description = "Managed HSM key ID (a Key Vault/HSM nested-item URL, e.g. https://<hsm-name>.managedhsm.azure.net/keys/<key-name>[/<version>] - NOT an ARM resource ID). Set exactly one of key_vault_key_id or managed_hsm_key_id. DEPRECATED upstream: azurerm has deprecated this field in favor of key_vault_key_id (which accepts the same URL shape for both Key Vault and Managed HSM keys) and removes it entirely in provider v5 - this module is pinned to < 5.0 (see versions.tf), so revisit this field before any v5 upgrade."
  type        = string
  default     = null

  validation {
    condition     = var.managed_hsm_key_id == null ? true : trimspace(var.managed_hsm_key_id) != ""
    error_message = "managed_hsm_key_id must be null or a non-empty Managed HSM key ID."
  }
}

variable "encryption_type" {
  description = "EncryptionAtRestWithCustomerKey, EncryptionAtRestWithPlatformAndCustomerKeys, or ConfidentialVmEncryptedWithCustomerKey."
  type        = string
  default     = "EncryptionAtRestWithCustomerKey"

  validation {
    condition = contains([
      "EncryptionAtRestWithCustomerKey",
      "EncryptionAtRestWithPlatformAndCustomerKeys",
      "ConfidentialVmEncryptedWithCustomerKey",
    ], var.encryption_type)
    error_message = "encryption_type must be EncryptionAtRestWithCustomerKey, EncryptionAtRestWithPlatformAndCustomerKeys, or ConfidentialVmEncryptedWithCustomerKey."
  }
}

variable "auto_key_rotation_enabled" {
  description = "Automatically use the latest key version when the Key Vault key is rotated. Requires a version-less key_vault_key_id."
  type        = bool
  default     = true
}

variable "federated_client_id" {
  description = "Multi-tenant application client ID, for encrypting resources in a different Azure AD tenant than the disk encryption set."
  type        = string
  default     = null

  validation {
    condition     = var.federated_client_id == null ? true : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.federated_client_id))
    error_message = "federated_client_id must be null or a GUID."
  }
}

variable "identity_type" {
  description = "SystemAssigned, UserAssigned, or SystemAssigned, UserAssigned. Whatever is chosen needs Key Vault Crypto Service Encryption User (or equivalent) on the key/vault - grant it at the pattern level with terraform-azurerm-compeer-role-assignments."
  type        = string
  default     = "SystemAssigned"

  validation {
    condition     = contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type)
    error_message = "identity_type must be SystemAssigned, UserAssigned, or SystemAssigned, UserAssigned."
  }
}

variable "identity_ids" {
  description = "User-assigned identity resource IDs. Required when identity_type = UserAssigned."
  type        = list(string)
  default     = null

  validation {
    condition = var.identity_ids == null ? true : (
      (
        alltrue([for id in var.identity_ids : trimspace(id) != ""]) &&
        length(var.identity_ids) == length(distinct(var.identity_ids))
      )
    )
    error_message = "identity_ids must be null or a distinct list of non-empty user-assigned identity resource IDs."
  }
}

variable "tags" {
  description = "Tags applied to the disk encryption set."
  type        = map(string)
  default     = {}
}
