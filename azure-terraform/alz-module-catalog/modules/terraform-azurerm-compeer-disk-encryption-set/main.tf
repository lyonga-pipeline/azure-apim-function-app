locals {
  uses_user_assigned_identity = contains(["UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type)
}

resource "azurerm_disk_encryption_set" "set" {
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
      # Plain `||` is NOT null-safe here: trimspace(null) errors regardless
      # of whether an earlier clause is already true, since Terraform does
      # not reliably short-circuit this expression. The ternary form avoids
      # ever calling trimspace() on a null key_vault_key_id (e.g. the
      # managed_hsm_key_id path).
      condition = !var.auto_key_rotation_enabled ? true : (
        var.key_vault_key_id == null ? true : (
          length(regexall("/keys/[^/]+$", trimspace(var.key_vault_key_id))) > 0
        )
      )
      error_message = "auto_key_rotation_enabled requires a versionless key_vault_key_id such as https://vault.vault.azure.net/keys/key-name."
    }
  }
}
