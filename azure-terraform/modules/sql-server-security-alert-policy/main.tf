resource "azurerm_mssql_server_security_alert_policy" "this" {
  resource_group_name        = var.resource_group_name
  server_name                = var.server_name
  state                      = var.state
  disabled_alerts            = var.disabled_alerts
  email_account_admins       = var.email_account_admins
  email_addresses            = var.email_addresses
  retention_days             = var.retention_days
  storage_endpoint           = var.storage_endpoint
  storage_account_access_key = var.storage_account_access_key

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
