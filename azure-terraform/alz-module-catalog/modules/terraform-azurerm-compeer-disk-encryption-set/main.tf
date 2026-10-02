locals {
  uses_user_assigned_identity = contains(["UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type)
  key_source_id               = var.key_vault_key_id != null ? var.key_vault_key_id : var.managed_hsm_key_id
}

resource "azurerm_disk_encryption_set" "set" {
  name                      = var.name
  resource_group_name       = var.resource_group_name
  location                  = var.location
  key_vault_key_id          = local.key_source_id
  encryption_type           = var.encryption_type
  auto_key_rotation_enabled = var.auto_key_rotation_enabled
  federated_client_id       = var.federated_client_id
  tags                      = var.tags

  identity {
    type         = var.identity_type
    identity_ids = local.uses_user_assigned_identity ? var.identity_ids : null
  }

  lifecycle {
    precondition {
      condition     = (var.key_vault_key_id != null) != (var.managed_hsm_key_id != null)
      error_message = "Set exactly one of key_vault_key_id or managed_hsm_key_id."
    }
    precondition {
      condition     = !local.uses_user_assigned_identity || try(length(var.identity_ids), 0) > 0
      error_message = "identity_ids is required when identity_type includes UserAssigned."
    }
    precondition {
      # Plain `||` is not null-safe here: trimspace(null) errors regardless
      # of whether an earlier clause is already true.
      condition = !var.auto_key_rotation_enabled ? true : (
        local.key_source_id == null ? true : (
          length(regexall("/keys/[^/]+$", trimspace(local.key_source_id))) > 0
        )
      )
      error_message = "auto_key_rotation_enabled requires a versionless key source ID such as https://vault.vault.azure.net/keys/key-name."
    }
  }
}
