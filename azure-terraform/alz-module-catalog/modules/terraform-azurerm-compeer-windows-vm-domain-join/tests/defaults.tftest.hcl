mock_provider "azurerm" {}

variables {
  virtual_machine_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Compute/virtualMachines/vm-dc01"
  domain_name        = "corp.example.com"
  domain_username    = "corp\\joiner"
  domain_password    = "Sup3rSecretP@ssw0rd!"
}

run "inline_password_path" {
  command = apply

  assert {
    condition     = azurerm_virtual_machine_extension.this.type == "JsonADDomainExtension"
    error_message = "wrong extension type"
  }
  assert {
    condition     = length(azurerm_virtual_machine_extension.this.protected_settings_from_key_vault) == 0
    error_message = "no KV protected settings block when inline password is used"
  }
}

run "key_vault_protected_settings_path" {
  command = apply

  variables {
    domain_password = "unused-but-required-shape"
    protected_settings_from_key_vault = {
      secret_url      = "https://kv.vault.azure.net/secrets/domain-join/abc"
      source_vault_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv"
    }
  }

  assert {
    condition     = length(azurerm_virtual_machine_extension.this.protected_settings_from_key_vault) == 1
    error_message = "KV protected settings block should render"
  }
}

run "rejects_bad_join_options" {
  command = plan
  variables {
    join_options = 999
  }
  expect_failures = [var.join_options]
}
