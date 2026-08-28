variable "name" {
  description = "Storage account name. Must be globally unique, 3-24 characters, lowercase letters and numbers only."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "Storage account names must be 3-24 lowercase alphanumeric characters."
  }
}

variable "resource_group_name" {
  description = "Resource group where the storage account is created."
  type        = string
}

variable "location" {
  description = "Azure region where the storage account is created."
  type        = string
}

variable "account_tier" {
  description = "Storage account tier."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "account_tier must be Standard or Premium."
  }
}

variable "account_replication_type" {
  description = "Storage account replication type."
  type        = string
  default     = "ZRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "account_replication_type must be one of LRS, GRS, RAGRS, ZRS, GZRS, or RAGZRS."
  }
}

variable "account_kind" {
  description = "Storage account kind."
  type        = string
  default     = "StorageV2"

  validation {
    condition     = contains(["BlobStorage", "BlockBlobStorage", "FileStorage", "Storage", "StorageV2"], var.account_kind)
    error_message = "account_kind must be BlobStorage, BlockBlobStorage, FileStorage, Storage, or StorageV2."
  }
}

variable "access_tier" {
  description = "Access tier for BlobStorage, FileStorage, and StorageV2 accounts where supported."
  type        = string
  default     = "Hot"

  validation {
    condition     = contains(["Hot", "Cool"], var.access_tier)
    error_message = "access_tier must be Hot or Cool."
  }
}

variable "edge_zone" {
  description = "Optional Azure edge zone for the storage account."
  type        = string
  default     = null
}

variable "min_tls_version" {
  description = "Minimum TLS version. Pattern modules should normally keep TLS1_2; the resource module allows valid Azure alternatives for legacy migration cases."
  type        = string
  default     = "TLS1_2"

  validation {
    condition     = contains(["TLS1_0", "TLS1_1", "TLS1_2"], var.min_tls_version)
    error_message = "min_tls_version must be TLS1_0, TLS1_1, or TLS1_2."
  }
}

variable "https_traffic_only_enabled" {
  description = "Require HTTPS traffic only."
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Whether public network access is allowed."
  type        = bool
  default     = false
}

variable "allow_nested_items_to_be_public" {
  description = "Whether nested items can be made public."
  type        = bool
  default     = false
}

variable "shared_access_key_enabled" {
  description = "Whether shared key authorization is enabled."
  type        = bool
  default     = false
}

variable "infrastructure_encryption_enabled" {
  description = "Whether infrastructure encryption is enabled."
  type        = bool
  default     = true
}

variable "is_hns_enabled" {
  description = "Whether hierarchical namespace is enabled."
  type        = bool
  default     = false
}

variable "sftp_enabled" {
  description = "Whether SFTP is enabled."
  type        = bool
  default     = false
}

variable "local_user_enabled" {
  description = "Whether local users are enabled."
  type        = bool
  default     = false
}

variable "nfsv3_enabled" {
  description = "Whether NFSv3 is enabled."
  type        = bool
  default     = false
}

variable "large_file_share_enabled" {
  description = "Whether large file shares are enabled."
  type        = bool
  default     = false
}

variable "cross_tenant_replication_enabled" {
  description = "Whether cross-tenant replication is enabled."
  type        = bool
  default     = false
}

variable "default_to_oauth_authentication" {
  description = "Whether Azure Files and Blob data plane operations default to OAuth authentication in the portal."
  type        = bool
  default     = true
}

variable "allowed_copy_scope" {
  description = "Optional allowed copy scope."
  type        = string
  default     = null

  validation {
    condition     = var.allowed_copy_scope == null ? true : contains(["AAD", "PrivateLink"], var.allowed_copy_scope)
    error_message = "allowed_copy_scope must be AAD or PrivateLink when set."
  }
}

variable "dns_endpoint_type" {
  description = "Optional DNS endpoint type."
  type        = string
  default     = null

  validation {
    condition     = var.dns_endpoint_type == null ? true : contains(["Standard", "AzureDnsZone"], var.dns_endpoint_type)
    error_message = "dns_endpoint_type must be Standard or AzureDnsZone when set."
  }
}

variable "queue_encryption_key_type" {
  description = "Encryption key type for the queue service."
  type        = string
  default     = null

  validation {
    condition     = var.queue_encryption_key_type == null ? true : contains(["Service", "Account"], var.queue_encryption_key_type)
    error_message = "queue_encryption_key_type must be Service or Account when set."
  }
}

variable "table_encryption_key_type" {
  description = "Encryption key type for the table service."
  type        = string
  default     = null

  validation {
    condition     = var.table_encryption_key_type == null ? true : contains(["Service", "Account"], var.table_encryption_key_type)
    error_message = "table_encryption_key_type must be Service or Account when set."
  }
}

variable "provisioned_billing_model_version" {
  description = "Optional provisioned billing model version for accounts that support it."
  type        = string
  default     = null
}

variable "identity" {
  description = "Optional managed identity configuration."
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

variable "customer_managed_key" {
  description = "Optional customer-managed key configuration. Set exactly one of key_vault_key_id or managed_hsm_key_id."
  type = object({
    key_vault_key_id          = optional(string)
    managed_hsm_key_id        = optional(string)
    user_assigned_identity_id = optional(string)
  })
  default = null

  validation {
    condition = var.customer_managed_key == null ? true : (
      (try(var.customer_managed_key.key_vault_key_id, null) != null) !=
      (try(var.customer_managed_key.managed_hsm_key_id, null) != null)
    )
    error_message = "customer_managed_key must set exactly one of key_vault_key_id or managed_hsm_key_id."
  }
}

variable "network_rules" {
  description = "Optional storage firewall and virtual network rules."
  type = object({
    default_action             = string
    bypass                     = optional(list(string), ["AzureServices"])
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
    private_link_access = optional(map(object({
      endpoint_resource_id = string
      endpoint_tenant_id   = optional(string)
    })), {})
  })
  default = null

  validation {
    condition     = var.network_rules == null ? true : contains(["Allow", "Deny"], var.network_rules.default_action)
    error_message = "network_rules.default_action must be Allow or Deny."
  }
}

variable "blob_properties" {
  description = "Optional blob service properties. delete_retention_days and container_delete_retention_days are kept for backward compatibility."
  type = object({
    versioning_enabled                = optional(bool, true)
    change_feed_enabled               = optional(bool, true)
    change_feed_retention_in_days     = optional(number)
    default_service_version           = optional(string)
    last_access_time_enabled          = optional(bool, false)
    delete_retention_days             = optional(number)
    container_delete_retention_days   = optional(number)
    restore_policy                    = optional(object({ days = number }))
    delete_retention_policy           = optional(object({ days = optional(number), permanent_delete_enabled = optional(bool) }))
    container_delete_retention_policy = optional(object({ days = optional(number) }))
    cors_rules = optional(map(object({
      allowed_headers    = list(string)
      allowed_methods    = list(string)
      allowed_origins    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    })), {})
  })
  default = null

  validation {
    condition = try(
      var.blob_properties.delete_retention_days == null ||
      (var.blob_properties.delete_retention_days >= 1 && var.blob_properties.delete_retention_days <= 365),
      true
    )
    error_message = "blob_properties.delete_retention_days must be between 1 and 365 when set."
  }

  validation {
    condition = try(
      var.blob_properties.container_delete_retention_days == null ||
      (var.blob_properties.container_delete_retention_days >= 1 && var.blob_properties.container_delete_retention_days <= 365),
      true
    )
    error_message = "blob_properties.container_delete_retention_days must be between 1 and 365 when set."
  }
}

variable "queue_properties" {
  description = "Optional queue service properties."
  type = object({
    logging = optional(object({
      delete                = optional(bool, true)
      read                  = optional(bool, true)
      write                 = optional(bool, true)
      version               = optional(string, "1.0")
      retention_policy_days = optional(number)
    }))
    hour_metrics = optional(object({
      enabled               = bool
      version               = string
      include_apis          = optional(bool)
      retention_policy_days = optional(number)
    }))
    minute_metrics = optional(object({
      enabled               = bool
      version               = string
      include_apis          = optional(bool)
      retention_policy_days = optional(number)
    }))
    cors_rules = optional(map(object({
      allowed_headers    = list(string)
      allowed_methods    = list(string)
      allowed_origins    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    })), {})
  })
  default = null
}

variable "share_properties" {
  description = "Optional Azure Files service properties."
  type = object({
    retention_policy = optional(object({
      days = optional(number)
    }))
    smb = optional(object({
      versions                        = optional(set(string))
      authentication_types            = optional(set(string))
      kerberos_ticket_encryption_type = optional(set(string))
      channel_encryption_type         = optional(set(string))
      multichannel_enabled            = optional(bool)
    }))
    cors_rules = optional(map(object({
      allowed_headers    = list(string)
      allowed_methods    = list(string)
      allowed_origins    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    })), {})
  })
  default = null
}

variable "azure_files_authentication" {
  description = "Optional Azure Files authentication configuration."
  type = object({
    directory_type                 = string
    default_share_level_permission = optional(string)
    active_directory = optional(object({
      domain_name         = string
      domain_guid         = string
      domain_sid          = optional(string)
      storage_sid         = optional(string)
      forest_name         = optional(string)
      netbios_domain_name = optional(string)
    }))
  })
  default = null
}

variable "custom_domain" {
  description = "Optional custom domain configuration."
  type = object({
    name          = string
    use_subdomain = optional(bool)
  })
  default = null
}

variable "immutability_policy" {
  description = "Optional account-level immutability policy."
  type = object({
    allow_protected_append_writes = optional(bool)
    period_since_creation_in_days = number
    state                         = string
  })
  default = null

  validation {
    condition     = var.immutability_policy == null ? true : contains(["Disabled", "Unlocked", "Locked"], var.immutability_policy.state)
    error_message = "immutability_policy.state must be Disabled, Unlocked, or Locked."
  }
}

variable "routing" {
  description = "Optional network routing preference."
  type = object({
    choice                      = optional(string)
    publish_internet_endpoints  = optional(bool)
    publish_microsoft_endpoints = optional(bool)
  })
  default = null

  validation {
    condition     = var.routing == null ? true : (try(var.routing.choice, null) == null ? true : contains(["MicrosoftRouting", "InternetRouting"], var.routing.choice))
    error_message = "routing.choice must be MicrosoftRouting or InternetRouting when set."
  }
}

variable "sas_policy" {
  description = "Optional shared access signature expiration policy."
  type = object({
    expiration_period = string
    expiration_action = optional(string)
  })
  default = null
}

variable "static_website" {
  description = "Optional static website configuration."
  type = object({
    index_document     = string
    error_404_document = optional(string)
  })
  default = null
}

variable "timeouts" {
  description = "Optional resource operation timeouts."
  type = object({
    create = optional(string)
    update = optional(string)
    read   = optional(string)
    delete = optional(string)
  })
  default = {}
}

variable "tags" {
  description = "Tags assigned to the storage account."
  type        = map(string)
  default     = {}
}
