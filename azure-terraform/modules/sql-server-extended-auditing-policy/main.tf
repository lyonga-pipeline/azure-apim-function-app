resource "azurerm_mssql_server_extended_auditing_policy" "this" {
  server_id                               = var.server_id
  enabled                                 = var.enabled
  log_monitoring_enabled                  = var.log_monitoring_enabled
  predicate_expression                    = var.predicate_expression
  retention_in_days                       = var.retention_in_days
  audit_actions_and_groups                = var.audit_actions_and_groups
  storage_endpoint                        = var.storage_endpoint
  storage_account_access_key              = var.storage_account_access_key
  storage_account_access_key_is_secondary = var.storage_account_access_key_is_secondary
  storage_account_subscription_id         = var.storage_account_subscription_id

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = try(timeouts.value.create, null)
      read   = try(timeouts.value.read, null)
      update = try(timeouts.value.update, null)
      delete = try(timeouts.value.delete, null)
    }
  }

  lifecycle {
    precondition {
      condition     = var.storage_account_access_key == null || var.storage_endpoint != null
      error_message = "storage_account_access_key requires storage_endpoint."
    }
  }
}
