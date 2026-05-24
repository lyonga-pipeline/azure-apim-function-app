resource "azurerm_storage_account" "this" {
  name                              = var.name
  resource_group_name               = var.resource_group_name
  location                          = var.location
  account_tier                      = coalesce(var.account_tier, "Standard")
  account_replication_type          = coalesce(var.account_replication_type, "ZRS")
  account_kind                      = coalesce(var.account_kind, "StorageV2")
  access_tier                       = coalesce(var.access_tier, "Hot")
  min_tls_version                   = coalesce(var.min_tls_version, "TLS1_2")
  public_network_access_enabled     = coalesce(var.public_network_access_enabled, false)
  allow_nested_items_to_be_public   = coalesce(var.allow_nested_items_to_be_public, false)
  shared_access_key_enabled         = coalesce(var.shared_access_key_enabled, false)
  infrastructure_encryption_enabled = coalesce(var.infrastructure_encryption_enabled, true)
  is_hns_enabled                    = coalesce(var.is_hns_enabled, false)
  sftp_enabled                      = coalesce(var.sftp_enabled, false)
  nfsv3_enabled                     = coalesce(var.nfsv3_enabled, false)
  large_file_share_enabled          = coalesce(var.large_file_share_enabled, false)
  cross_tenant_replication_enabled  = coalesce(var.cross_tenant_replication_enabled, false)
  default_to_oauth_authentication   = coalesce(var.default_to_oauth_authentication, true)
  tags                              = var.tags

  dynamic "identity" {
    for_each = var.identity == null ? [] : [var.identity]
    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  dynamic "network_rules" {
    for_each = var.network_rules == null ? [] : [var.network_rules]
    content {
      default_action             = network_rules.value.default_action
      bypass                     = try(network_rules.value.bypass, ["AzureServices"])
      ip_rules                   = try(network_rules.value.ip_rules, [])
      virtual_network_subnet_ids = try(network_rules.value.virtual_network_subnet_ids, [])
    }
  }

  dynamic "blob_properties" {
    for_each = var.blob_properties == null ? [] : [var.blob_properties]
    content {
      versioning_enabled       = try(blob_properties.value.versioning_enabled, true)
      change_feed_enabled      = try(blob_properties.value.change_feed_enabled, true)
      last_access_time_enabled = try(blob_properties.value.last_access_time_enabled, false)

      dynamic "delete_retention_policy" {
        for_each = try(blob_properties.value.delete_retention_days, null) == null ? [] : [1]
        content {
          days = blob_properties.value.delete_retention_days
        }
      }

      dynamic "container_delete_retention_policy" {
        for_each = try(blob_properties.value.container_delete_retention_days, null) == null ? [] : [1]
        content {
          days = blob_properties.value.container_delete_retention_days
        }
      }
    }
  }

  dynamic "queue_properties" {
    for_each = var.queue_properties == null ? [] : [var.queue_properties]
    content {
      dynamic "logging" {
        for_each = try(queue_properties.value.logging, null) == null ? [] : [queue_properties.value.logging]
        content {
          delete                = try(logging.value.delete, true)
          read                  = try(logging.value.read, true)
          write                 = try(logging.value.write, true)
          version               = try(logging.value.version, "1.0")
          retention_policy_days = try(logging.value.retention_policy_days, 10)
        }
      }
    }
  }

  dynamic "static_website" {
    for_each = var.static_website == null ? [] : [var.static_website]
    content {
      index_document     = static_website.value.index_document
      error_404_document = try(static_website.value.error_404_document, null)
    }
  }
}
