resource "azurerm_storage_account_customer_managed_key" "this" {
  storage_account_id           = var.storage_account_id
  key_vault_key_id             = var.key_vault_key_id
  user_assigned_identity_id    = var.user_assigned_identity_id
  federated_identity_client_id = var.federated_identity_client_id

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
