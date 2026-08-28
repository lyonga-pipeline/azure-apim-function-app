resource "azurerm_recovery_services_vault" "this" {
  name                               = var.name
  resource_group_name                = var.resource_group_name
  location                           = var.location
  sku                                = var.sku
  soft_delete_enabled                = var.soft_delete_enabled
  storage_mode_type                  = var.storage_mode_type
  public_network_access_enabled      = var.public_network_access_enabled
  immutability                       = var.immutability
  cross_region_restore_enabled       = var.cross_region_restore_enabled
  classic_vmware_replication_enabled = var.classic_vmware_replication_enabled
  tags                               = var.tags

  dynamic "identity" {
    for_each = var.identity == null ? [] : [var.identity]
    content {
      type         = identity.value.type
      identity_ids = length(try(identity.value.identity_ids, [])) == 0 ? null : identity.value.identity_ids
    }
  }

  dynamic "encryption" {
    for_each = var.encryption == null ? [] : [var.encryption]
    content {
      key_id                            = encryption.value.key_id
      infrastructure_encryption_enabled = try(encryption.value.infrastructure_encryption_enabled, null)
      use_system_assigned_identity      = try(encryption.value.use_system_assigned_identity, null)
      user_assigned_identity_id         = try(encryption.value.user_assigned_identity_id, null)
    }
  }

  dynamic "monitoring" {
    for_each = var.monitoring == null ? [] : [var.monitoring]
    content {
      alerts_for_all_job_failures_enabled            = try(monitoring.value.alerts_for_all_job_failures_enabled, null)
      alerts_for_all_failover_issues_enabled         = try(monitoring.value.alerts_for_all_failover_issues_enabled, null)
      alerts_for_all_replication_issues_enabled      = try(monitoring.value.alerts_for_all_replication_issues_enabled, null)
      alerts_for_critical_operation_failures_enabled = try(monitoring.value.alerts_for_critical_operation_failures_enabled, null)
      email_notifications_for_site_recovery_enabled  = try(monitoring.value.email_notifications_for_site_recovery_enabled, null)
    }
  }

  timeouts {
    create = try(var.timeouts.create, null)
    update = try(var.timeouts.update, null)
    read   = try(var.timeouts.read, null)
    delete = try(var.timeouts.delete, null)
  }
}
