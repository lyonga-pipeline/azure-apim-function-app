resource "azurerm_storage_account" "this" {
  name                              = var.name
  resource_group_name               = var.resource_group_name
  location                          = var.location
  account_tier                      = var.account_tier
  account_replication_type          = var.account_replication_type
  account_kind                      = var.account_kind
  access_tier                       = var.access_tier
  edge_zone                         = var.edge_zone
  min_tls_version                   = var.min_tls_version
  https_traffic_only_enabled        = var.https_traffic_only_enabled
  public_network_access_enabled     = var.public_network_access_enabled
  allow_nested_items_to_be_public   = var.allow_nested_items_to_be_public
  shared_access_key_enabled         = var.shared_access_key_enabled
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled
  is_hns_enabled                    = var.is_hns_enabled
  sftp_enabled                      = var.sftp_enabled
  local_user_enabled                = var.local_user_enabled
  nfsv3_enabled                     = var.nfsv3_enabled
  large_file_share_enabled          = var.large_file_share_enabled
  cross_tenant_replication_enabled  = var.cross_tenant_replication_enabled
  default_to_oauth_authentication   = var.default_to_oauth_authentication
  allowed_copy_scope                = var.allowed_copy_scope
  dns_endpoint_type                 = var.dns_endpoint_type
  queue_encryption_key_type         = var.queue_encryption_key_type
  table_encryption_key_type         = var.table_encryption_key_type
  provisioned_billing_model_version = var.provisioned_billing_model_version
  tags                              = var.tags

  dynamic "identity" {
    for_each = var.identity == null ? [] : [var.identity]
    content {
      type         = identity.value.type
      identity_ids = length(try(identity.value.identity_ids, [])) == 0 ? null : identity.value.identity_ids
    }
  }

  dynamic "customer_managed_key" {
    for_each = var.customer_managed_key == null ? [] : [var.customer_managed_key]
    content {
      key_vault_key_id          = try(customer_managed_key.value.key_vault_key_id, null)
      managed_hsm_key_id        = try(customer_managed_key.value.managed_hsm_key_id, null)
      user_assigned_identity_id = try(customer_managed_key.value.user_assigned_identity_id, null)
    }
  }

  dynamic "network_rules" {
    for_each = var.network_rules == null ? [] : [var.network_rules]
    content {
      default_action             = network_rules.value.default_action
      bypass                     = try(network_rules.value.bypass, ["AzureServices"])
      ip_rules                   = try(network_rules.value.ip_rules, [])
      virtual_network_subnet_ids = try(network_rules.value.virtual_network_subnet_ids, [])

      dynamic "private_link_access" {
        for_each = try(network_rules.value.private_link_access, {})
        content {
          endpoint_resource_id = private_link_access.value.endpoint_resource_id
          endpoint_tenant_id   = try(private_link_access.value.endpoint_tenant_id, null)
        }
      }
    }
  }

  dynamic "blob_properties" {
    for_each = var.blob_properties == null ? [] : [var.blob_properties]
    content {
      versioning_enabled            = try(blob_properties.value.versioning_enabled, true)
      change_feed_enabled           = try(blob_properties.value.change_feed_enabled, true)
      change_feed_retention_in_days = try(blob_properties.value.change_feed_retention_in_days, null)
      default_service_version       = try(blob_properties.value.default_service_version, null)
      last_access_time_enabled      = try(blob_properties.value.last_access_time_enabled, false)

      dynamic "restore_policy" {
        for_each = try(blob_properties.value.restore_policy, null) == null ? [] : [blob_properties.value.restore_policy]
        content {
          days = restore_policy.value.days
        }
      }

      dynamic "delete_retention_policy" {
        for_each = try(blob_properties.value.delete_retention_policy, null) == null && try(blob_properties.value.delete_retention_days, null) == null ? [] : [
          merge(
            { days = try(blob_properties.value.delete_retention_days, null) },
            try(blob_properties.value.delete_retention_policy, {})
          )
        ]
        content {
          days                     = try(delete_retention_policy.value.days, null)
          permanent_delete_enabled = try(delete_retention_policy.value.permanent_delete_enabled, null)
        }
      }

      dynamic "container_delete_retention_policy" {
        for_each = try(blob_properties.value.container_delete_retention_policy, null) == null && try(blob_properties.value.container_delete_retention_days, null) == null ? [] : [
          merge(
            { days = try(blob_properties.value.container_delete_retention_days, null) },
            try(blob_properties.value.container_delete_retention_policy, {})
          )
        ]
        content {
          days = try(container_delete_retention_policy.value.days, null)
        }
      }

      dynamic "cors_rule" {
        for_each = try(blob_properties.value.cors_rules, {})
        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
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
          retention_policy_days = try(logging.value.retention_policy_days, null)
        }
      }

      dynamic "hour_metrics" {
        for_each = try(queue_properties.value.hour_metrics, null) == null ? [] : [queue_properties.value.hour_metrics]
        content {
          enabled               = hour_metrics.value.enabled
          version               = hour_metrics.value.version
          include_apis          = try(hour_metrics.value.include_apis, null)
          retention_policy_days = try(hour_metrics.value.retention_policy_days, null)
        }
      }

      dynamic "minute_metrics" {
        for_each = try(queue_properties.value.minute_metrics, null) == null ? [] : [queue_properties.value.minute_metrics]
        content {
          enabled               = minute_metrics.value.enabled
          version               = minute_metrics.value.version
          include_apis          = try(minute_metrics.value.include_apis, null)
          retention_policy_days = try(minute_metrics.value.retention_policy_days, null)
        }
      }

      dynamic "cors_rule" {
        for_each = try(queue_properties.value.cors_rules, {})
        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }
    }
  }

  dynamic "share_properties" {
    for_each = var.share_properties == null ? [] : [var.share_properties]
    content {
      dynamic "retention_policy" {
        for_each = try(share_properties.value.retention_policy, null) == null ? [] : [share_properties.value.retention_policy]
        content {
          days = try(retention_policy.value.days, null)
        }
      }

      dynamic "smb" {
        for_each = try(share_properties.value.smb, null) == null ? [] : [share_properties.value.smb]
        content {
          versions                        = try(smb.value.versions, null)
          authentication_types            = try(smb.value.authentication_types, null)
          kerberos_ticket_encryption_type = try(smb.value.kerberos_ticket_encryption_type, null)
          channel_encryption_type         = try(smb.value.channel_encryption_type, null)
          multichannel_enabled            = try(smb.value.multichannel_enabled, null)
        }
      }

      dynamic "cors_rule" {
        for_each = try(share_properties.value.cors_rules, {})
        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }
    }
  }

  dynamic "azure_files_authentication" {
    for_each = var.azure_files_authentication == null ? [] : [var.azure_files_authentication]
    content {
      directory_type                 = azure_files_authentication.value.directory_type
      default_share_level_permission = try(azure_files_authentication.value.default_share_level_permission, null)

      dynamic "active_directory" {
        for_each = try(azure_files_authentication.value.active_directory, null) == null ? [] : [azure_files_authentication.value.active_directory]
        content {
          domain_name         = active_directory.value.domain_name
          domain_guid         = active_directory.value.domain_guid
          domain_sid          = try(active_directory.value.domain_sid, null)
          storage_sid         = try(active_directory.value.storage_sid, null)
          forest_name         = try(active_directory.value.forest_name, null)
          netbios_domain_name = try(active_directory.value.netbios_domain_name, null)
        }
      }
    }
  }

  dynamic "custom_domain" {
    for_each = var.custom_domain == null ? [] : [var.custom_domain]
    content {
      name          = custom_domain.value.name
      use_subdomain = try(custom_domain.value.use_subdomain, null)
    }
  }

  dynamic "immutability_policy" {
    for_each = var.immutability_policy == null ? [] : [var.immutability_policy]
    content {
      allow_protected_append_writes = try(immutability_policy.value.allow_protected_append_writes, null)
      period_since_creation_in_days = immutability_policy.value.period_since_creation_in_days
      state                         = immutability_policy.value.state
    }
  }

  dynamic "routing" {
    for_each = var.routing == null ? [] : [var.routing]
    content {
      choice                      = try(routing.value.choice, null)
      publish_internet_endpoints  = try(routing.value.publish_internet_endpoints, null)
      publish_microsoft_endpoints = try(routing.value.publish_microsoft_endpoints, null)
    }
  }

  dynamic "sas_policy" {
    for_each = var.sas_policy == null ? [] : [var.sas_policy]
    content {
      expiration_period = sas_policy.value.expiration_period
      expiration_action = try(sas_policy.value.expiration_action, null)
    }
  }

  dynamic "static_website" {
    for_each = var.static_website == null ? [] : [var.static_website]
    content {
      index_document     = static_website.value.index_document
      error_404_document = try(static_website.value.error_404_document, null)
    }
  }

  lifecycle {
    precondition {
      condition     = !var.sftp_enabled || var.is_hns_enabled
      error_message = "sftp_enabled requires is_hns_enabled = true."
    }

    precondition {
      condition = var.customer_managed_key == null ? true : (
        (try(var.customer_managed_key.key_vault_key_id, null) != null) !=
        (try(var.customer_managed_key.managed_hsm_key_id, null) != null)
      )
      error_message = "customer_managed_key must configure exactly one of key_vault_key_id or managed_hsm_key_id."
    }

    precondition {
      condition = var.customer_managed_key == null ? true : (
        try(var.customer_managed_key.user_assigned_identity_id, null) != null
      )
      error_message = "customer_managed_key requires user_assigned_identity_id."
    }

    precondition {
      condition     = !var.nfsv3_enabled || var.is_hns_enabled
      error_message = "nfsv3_enabled requires is_hns_enabled = true."
    }
  }

  timeouts {
    create = try(var.timeouts.create, null)
    update = try(var.timeouts.update, null)
    read   = try(var.timeouts.read, null)
    delete = try(var.timeouts.delete, null)
  }
}
