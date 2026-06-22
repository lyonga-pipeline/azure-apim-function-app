variable "name" {
  type = string
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "Storage account names must be 3-24 lowercase alphanumeric characters."
  }
}
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "account_tier" {
  type    = string
  default = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "account_tier must be Standard or Premium."
  }
}
variable "account_replication_type" {
  type    = string
  default = "ZRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "account_replication_type must be one of LRS, GRS, RAGRS, ZRS, GZRS, or RAGZRS."
  }
}
variable "account_kind" {
  type    = string
  default = "StorageV2"

  validation {
    condition     = contains(["BlobStorage", "BlockBlobStorage", "FileStorage", "Storage", "StorageV2"], var.account_kind)
    error_message = "account_kind must be BlobStorage, BlockBlobStorage, FileStorage, Storage, or StorageV2."
  }
}
variable "access_tier" {
  type    = string
  default = "Hot"

  validation {
    condition     = contains(["Hot", "Cool"], var.access_tier)
    error_message = "access_tier must be Hot or Cool."
  }
}
variable "min_tls_version" {
  type    = string
  default = "TLS1_2"

  validation {
    condition     = var.min_tls_version == "TLS1_2"
    error_message = "min_tls_version must remain TLS1_2 for the enterprise storage baseline."
  }
}
variable "public_network_access_enabled" {
  type    = bool
  default = false
}
variable "allow_nested_items_to_be_public" {
  type    = bool
  default = false
}
variable "shared_access_key_enabled" {
  type    = bool
  default = false
}
variable "infrastructure_encryption_enabled" {
  type    = bool
  default = true
}
variable "is_hns_enabled" {
  type    = bool
  default = false
}
variable "sftp_enabled" {
  type    = bool
  default = false
}
variable "nfsv3_enabled" {
  type    = bool
  default = false
}
variable "large_file_share_enabled" {
  type    = bool
  default = false
}
variable "cross_tenant_replication_enabled" {
  type    = bool
  default = false
}
variable "default_to_oauth_authentication" {
  type    = bool
  default = true
}
variable "identity" {
  type = object({
    type         = string
    identity_ids = optional(list(string), [])
  })
  default = null

  validation {
    condition = var.identity == null ? true : contains([
      "SystemAssigned",
      "UserAssigned",
      "SystemAssigned, UserAssigned"
    ], var.identity.type)
    error_message = "identity.type must be SystemAssigned, UserAssigned, or 'SystemAssigned, UserAssigned'."
  }
}
variable "network_rules" {
  type = object({
    default_action             = string
    bypass                     = optional(list(string), ["AzureServices"])
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  default = null

  validation {
    condition     = var.network_rules == null ? true : contains(["Allow", "Deny"], var.network_rules.default_action)
    error_message = "network_rules.default_action must be Allow or Deny."
  }
}
variable "blob_properties" {
  type = object({
    versioning_enabled              = optional(bool, true)
    change_feed_enabled             = optional(bool, true)
    last_access_time_enabled        = optional(bool, false)
    delete_retention_days           = optional(number)
    container_delete_retention_days = optional(number)
  })
  default = null

  validation {
    condition = var.blob_properties == null || (
      try(var.blob_properties.delete_retention_days, null) == null ||
      (var.blob_properties.delete_retention_days >= 1 && var.blob_properties.delete_retention_days <= 365)
    )
    error_message = "blob_properties.delete_retention_days must be between 1 and 365 when set."
  }

  validation {
    condition = var.blob_properties == null || (
      try(var.blob_properties.container_delete_retention_days, null) == null ||
      (var.blob_properties.container_delete_retention_days >= 1 && var.blob_properties.container_delete_retention_days <= 365)
    )
    error_message = "blob_properties.container_delete_retention_days must be between 1 and 365 when set."
  }
}
variable "queue_properties" {
  type = object({
    logging = optional(object({
      delete                = optional(bool, true)
      read                  = optional(bool, true)
      write                 = optional(bool, true)
      version               = optional(string, "1.0")
      retention_policy_days = optional(number, 10)
    }))
  })
  default = null
}
variable "static_website" {
  type = object({
    index_document     = string
    error_404_document = optional(string)
  })
  default = null
}
variable "tags" {
  type    = map(string)
  default = {}
}
