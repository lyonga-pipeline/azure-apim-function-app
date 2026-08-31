locals {
  use_key_vault_protected_settings = var.protected_settings_from_key_vault != null
}

resource "azurerm_virtual_machine_extension" "this" {
  name                        = var.name
  virtual_machine_id          = var.virtual_machine_id
  publisher                   = "Microsoft.Compute"
  type                        = "JsonADDomainExtension"
  type_handler_version        = var.type_handler_version
  auto_upgrade_minor_version  = var.auto_upgrade_minor_version
  automatic_upgrade_enabled   = var.automatic_upgrade_enabled
  failure_suppression_enabled = var.failure_suppression_enabled
  provision_after_extensions  = length(var.provision_after_extensions) == 0 ? null : var.provision_after_extensions
  tags                        = var.tags

  settings = jsonencode({
    Name    = var.domain_name
    OUPath  = var.ou_path
    User    = var.domain_username
    Restart = tostring(var.restart)
    Options = var.join_options
  })

  # Backward-compatible inline password path. For new enterprise patterns,
  # prefer protected_settings_from_key_vault so the extension receives a Key
  # Vault-hosted protected-settings JSON document rather than an inline secret.
  protected_settings = local.use_key_vault_protected_settings ? null : jsonencode({
    Password = var.domain_password
  })

  dynamic "protected_settings_from_key_vault" {
    for_each = local.use_key_vault_protected_settings ? [var.protected_settings_from_key_vault] : []
    content {
      secret_url      = protected_settings_from_key_vault.value.secret_url
      source_vault_id = protected_settings_from_key_vault.value.source_vault_id
    }
  }

  timeouts {
    create = try(var.timeouts.create, null)
    read   = try(var.timeouts.read, null)
    update = try(var.timeouts.update, null)
    delete = try(var.timeouts.delete, null)
  }

  lifecycle {
    precondition {
      condition     = length(trimspace(var.domain_name)) > 0
      error_message = "domain_name must not be empty."
    }

    precondition {
      condition     = length(trimspace(var.domain_username)) > 0
      error_message = "domain_username must not be empty."
    }

    precondition {
      condition = (
        local.use_key_vault_protected_settings ||
        try(length(trimspace(var.domain_password)) > 0, false)
      )
      error_message = "Set either domain_password or protected_settings_from_key_vault."
    }
  }
}
