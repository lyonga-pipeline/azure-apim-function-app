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
}
variable "account_replication_type" {
  type    = string
  default = "ZRS"
}
variable "account_kind" {
  type    = string
  default = "StorageV2"
}
variable "access_tier" {
  type    = string
  default = "Hot"
}
variable "min_tls_version" {
  type    = string
  default = "TLS1_2"
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
  default = true
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
}
variable "network_rules" {
  type = object({
    default_action             = string
    bypass                     = optional(list(string), ["AzureServices"])
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  default = null
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
