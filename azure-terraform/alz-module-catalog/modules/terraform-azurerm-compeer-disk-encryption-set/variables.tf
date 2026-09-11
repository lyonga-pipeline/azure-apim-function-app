variable "name" {
  description = "Name of the disk encryption set."
  type        = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "key_vault_key_id" {
  description = "Versioned or version-less Key Vault key ID (from a Standard/Premium vault). Set exactly one of key_vault_key_id or managed_hsm_key_id."
  type        = string
  default     = null
}

variable "managed_hsm_key_id" {
  description = "Managed HSM key ID. Set exactly one of key_vault_key_id or managed_hsm_key_id."
  type        = string
  default     = null
}

variable "encryption_type" {
  description = "EncryptionAtRestWithCustomerKey, EncryptionAtRestWithPlatformAndCustomerKeys, or EncryptionAtRestWithPlatformKey."
  type        = string
  default     = "EncryptionAtRestWithCustomerKey"

  validation {
    condition = contains([
      "EncryptionAtRestWithCustomerKey",
      "EncryptionAtRestWithPlatformAndCustomerKeys",
      "EncryptionAtRestWithPlatformKey",
    ], var.encryption_type)
    error_message = "encryption_type must be EncryptionAtRestWithCustomerKey, EncryptionAtRestWithPlatformAndCustomerKeys, or EncryptionAtRestWithPlatformKey."
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
}

variable "identity_type" {
  description = "SystemAssigned or UserAssigned. Whatever is chosen needs Key Vault Crypto Service Encryption User (or equivalent) on the key/vault - grant it at the pattern level with terraform-azurerm-compeer-role-assignments."
  type        = string
  default     = "SystemAssigned"

  validation {
    condition     = contains(["SystemAssigned", "UserAssigned"], var.identity_type)
    error_message = "identity_type must be SystemAssigned or UserAssigned."
  }
}

variable "identity_ids" {
  description = "User-assigned identity resource IDs. Required when identity_type = UserAssigned."
  type        = list(string)
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
