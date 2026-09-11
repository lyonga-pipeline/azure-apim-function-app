mock_provider "azurerm" {}

run "empty_is_noop" {
  command = plan

  assert {
    condition     = length(azurerm_management_lock.this) == 0
    error_message = "no locks by default"
  }
}

run "defaults_to_can_not_delete" {
  command = plan

  variables {
    locks = {
      rg-prod = {
        scope = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-prod"
      }
    }
  }

  assert {
    condition     = azurerm_management_lock.this["rg-prod"].name == "rg-prod-lock"
    error_message = "default lock name should use the stable input key"
  }

  assert {
    condition     = azurerm_management_lock.this["rg-prod"].lock_level == "CanNotDelete"
    error_message = "lock level should default to CanNotDelete"
  }
}

run "creates_explicit_can_not_delete_and_read_only_locks" {
  command = plan

  variables {
    locks = {
      rg-prod = {
        name       = "rg-prod-cannot-delete"
        scope      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-prod"
        lock_level = "CanNotDelete"
        notes      = "Protect production resource group from accidental deletion."
      }

      storage-readonly = {
        name       = "storage-readonly"
        scope      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-prod/providers/Microsoft.Storage/storageAccounts/stprod001"
        lock_level = "ReadOnly"
        notes      = "Block control-plane updates to the storage account."
      }
    }
  }

  assert {
    condition     = length(azurerm_management_lock.this) == 2
    error_message = "both explicit lock levels should create locks"
  }

  assert {
    condition     = azurerm_management_lock.this["rg-prod"].lock_level == "CanNotDelete"
    error_message = "explicit CanNotDelete lock level not wired"
  }

  assert {
    condition     = azurerm_management_lock.this["rg-prod"].notes == "Protect production resource group from accidental deletion."
    error_message = "lock notes should be passed through"
  }

  assert {
    condition     = azurerm_management_lock.this["storage-readonly"].lock_level == "ReadOnly"
    error_message = "explicit ReadOnly lock level not wired"
  }
}

run "supports_subscription_resource_group_and_resource_scopes" {
  command = plan

  variables {
    locks = {
      subscription = {
        scope      = "/subscriptions/00000000-0000-0000-0000-000000000000"
        lock_level = "CanNotDelete"
      }

      resource_group = {
        scope      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-platform"
        lock_level = "CanNotDelete"
      }

      resource = {
        scope      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-platform/providers/Microsoft.KeyVault/vaults/kv-platform"
        lock_level = "ReadOnly"
      }
    }
  }

  assert {
    condition     = length(azurerm_management_lock.this) == 3
    error_message = "subscription, resource group, and resource scopes should be accepted"
  }

  assert {
    condition     = azurerm_management_lock.this["subscription"].scope == "/subscriptions/00000000-0000-0000-0000-000000000000"
    error_message = "subscription scope should be passed through"
  }

  assert {
    condition     = azurerm_management_lock.this["resource_group"].scope == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-platform"
    error_message = "resource group scope should be passed through"
  }

  assert {
    condition     = azurerm_management_lock.this["resource"].scope == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-platform/providers/Microsoft.KeyVault/vaults/kv-platform"
    error_message = "resource scope should be passed through"
  }
}

run "rejects_invalid_lock_level" {
  command = plan

  variables {
    locks = {
      rg-prod = { scope = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-prod", lock_level = "DeleteOnly" }
    }
  }
  expect_failures = [var.locks]
}

run "rejects_empty_scope" {
  command = plan

  variables {
    locks = {
      rg-prod = { scope = "", lock_level = "CanNotDelete" }
    }
  }
  expect_failures = [var.locks]
}

run "rejects_empty_name" {
  command = plan

  variables {
    locks = {
      rg-prod = {
        name       = " "
        scope      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-prod"
        lock_level = "CanNotDelete"
      }
    }
  }

  expect_failures = [var.locks]
}

run "rejects_management_group_scope" {
  command = plan

  variables {
    locks = {
      platform = {
        scope      = "/providers/Microsoft.Management/managementGroups/platform-mg"
        lock_level = "CanNotDelete"
      }
    }
  }

  expect_failures = [var.locks]
}
