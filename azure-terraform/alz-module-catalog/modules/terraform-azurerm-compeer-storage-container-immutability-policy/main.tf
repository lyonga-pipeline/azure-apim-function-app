resource "azurerm_storage_container_immutability_policy" "this" {
  storage_container_resource_manager_id = var.storage_container_resource_manager_id
  immutability_period_in_days           = var.immutability_period_in_days
  locked                                = var.locked
  protected_append_writes_enabled       = var.protected_append_writes_enabled
  protected_append_writes_all_enabled   = var.protected_append_writes_all_enabled

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = try(timeouts.value.create, null)
      read   = try(timeouts.value.read, null)
      update = try(timeouts.value.update, null)
      delete = try(timeouts.value.delete, null)
    }
  }
}
