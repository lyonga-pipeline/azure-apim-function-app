resource "azurerm_disk_encryption_set" "this" {
  name                      = var.name
  resource_group_name       = var.resource_group_name
  location                  = var.location
  key_vault_key_id          = var.key_vault_key_id
  managed_hsm_key_id        = var.managed_hsm_key_id
  encryption_type           = var.encryption_type
  auto_key_rotation_enabled = var.auto_key_rotation_enabled
  federated_client_id       = var.federated_client_id
  tags                      = var.tags

  identity {
    type         = var.identity_type
    identity_ids = var.identity_type == "UserAssigned" ? var.identity_ids : null
  }

  lifecycle {
    precondition {
      condition     = (var.key_vault_key_id != null) != (var.managed_hsm_key_id != null)
      error_message = "Set exactly one of key_vault_key_id or managed_hsm_key_id."
    }
    precondition {
      condition     = var.identity_type != "UserAssigned" || try(length(var.identity_ids), 0) > 0
      error_message = "identity_ids is required when identity_type = UserAssigned."
    }
  }
}
