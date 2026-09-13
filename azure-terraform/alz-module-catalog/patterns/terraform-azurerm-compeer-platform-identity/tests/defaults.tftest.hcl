mock_provider "azurerm" {}

# Had zero test coverage before this file, including the disk_encryption_sets
# wiring added this session and the management_locks scope/scope_key
# validation.

variables {
  subscription_id = "00000000-0000-0000-0000-000000000000"
  tenant_id       = "11111111-1111-1111-1111-111111111111"
  location        = "centralus"
  environment     = "prod"
  resource_group  = { name = "rg-platform-identity" }
  key_vault       = {}
}

run "empty_config_is_a_noop" {
  command = plan
  assert {
    condition     = length(module.platform_identities) == 0 && length(module.disk_encryption_sets) == 0
    error_message = "no identities or disk encryption sets by default"
  }
}

run "platform_identity_and_des_created" {
  command = plan
  variables {
    platform_identities = {
      automation = {}
    }
    disk_encryption_sets = {
      platform = {
        name             = "des-platform-prod"
        key_vault_key_id = "https://kv-platform-prod.vault.azure.net/keys/des-key/abc123"
      }
    }
  }
  assert {
    condition     = length(module.platform_identities) == 1
    error_message = "expected one user-assigned identity"
  }
  assert {
    condition     = length(module.disk_encryption_sets) == 1
    error_message = "expected one disk encryption set"
  }
}

run "management_lock_requires_exactly_one_scope_specifier" {
  command = plan
  variables {
    management_locks = {
      kv = { name = "lock-kv", scope = "/subscriptions/x/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv", scope_key = "key_vault" }
    }
  }
  expect_failures = [var.management_locks]
}

run "management_lock_by_scope_key_passes" {
  command = apply
  variables {
    management_locks = {
      kv = { name = "lock-kv", scope_key = "key_vault" }
    }
  }
  assert {
    condition     = local.management_lock_inputs["kv"].scope == module.key_vault.id
    error_message = "expected scope_key=key_vault to resolve to the key vault's ID"
  }
}
