mock_provider "azurerm" {}

variables {
  name                = "des-platform-prod"
  resource_group_name = "rg-platform-security-prod"
  location            = "centralus"
  key_vault_key_id    = "https://kv-platform-prod.vault.azure.net/keys/des-key"
}

run "creates_with_key_vault_key" {
  command = plan
  assert {
    condition     = azurerm_disk_encryption_set.set.encryption_type == "EncryptionAtRestWithCustomerKey"
    error_message = "default encryption_type should be EncryptionAtRestWithCustomerKey"
  }
}

run "outputs_are_wired" {
  # None of the other 20 runs in this file ever assert against output.* -
  # only the underlying resource attributes - so an output-wiring bug
  # (wrong field, wrong index) would have passed every prior test.
  command = apply

  assert {
    condition = (
      output.id == azurerm_disk_encryption_set.set.id &&
      output.name == azurerm_disk_encryption_set.set.name &&
      output.identity_principal_id == azurerm_disk_encryption_set.set.identity[0].principal_id &&
      output.identity_tenant_id == azurerm_disk_encryption_set.set.identity[0].tenant_id
    )
    error_message = "every output must echo its corresponding resource attribute"
  }
}

run "accepts_versioned_key_when_rotation_disabled" {
  command = plan
  variables {
    key_vault_key_id          = "https://kv-platform-prod.vault.azure.net/keys/des-key/abc123"
    auto_key_rotation_enabled = false
  }
  assert {
    condition     = azurerm_disk_encryption_set.set.key_vault_key_id == "https://kv-platform-prod.vault.azure.net/keys/des-key/abc123"
    error_message = "versioned key IDs should be accepted when auto rotation is disabled"
  }
}

run "accepts_managed_hsm_key" {
  command = plan
  variables {
    key_vault_key_id   = null
    managed_hsm_key_id = "https://hsm1.managedhsm.azure.net/keys/key1"
  }
  assert {
    condition     = azurerm_disk_encryption_set.set.key_vault_key_id == "https://hsm1.managedhsm.azure.net/keys/key1"
    error_message = "managed_hsm_key_id should be wired through key_vault_key_id"
  }
}

run "rejects_no_key_source" {
  command = plan
  variables {
    key_vault_key_id = null
  }
  expect_failures = [azurerm_disk_encryption_set.set]
}

run "rejects_versioned_key_with_auto_rotation" {
  command = plan
  variables {
    key_vault_key_id = "https://kv-platform-prod.vault.azure.net/keys/des-key/abc123"
  }
  expect_failures = [azurerm_disk_encryption_set.set]
}

run "rejects_both_key_sources" {
  command = plan
  variables {
    managed_hsm_key_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.KeyVault/managedHSMs/hsm1/keys/key1"
  }
  expect_failures = [azurerm_disk_encryption_set.set]
}

run "rejects_user_assigned_without_identity_ids" {
  command = plan
  variables {
    identity_type = "UserAssigned"
  }
  expect_failures = [azurerm_disk_encryption_set.set]
}

run "system_and_user_assigned_identity" {
  command = plan
  variables {
    identity_type = "SystemAssigned, UserAssigned"
    identity_ids  = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mi-des"]
  }
  assert {
    condition     = azurerm_disk_encryption_set.set.identity[0].type == "SystemAssigned, UserAssigned"
    error_message = "identity type should support SystemAssigned, UserAssigned"
  }
}

run "user_assigned_identity" {
  command = plan
  variables {
    identity_type = "UserAssigned"
    identity_ids  = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mi-des"]
  }
  assert {
    condition     = azurerm_disk_encryption_set.set.identity[0].type == "UserAssigned"
    error_message = "identity type should be UserAssigned"
  }
}

run "confidential_vm_encryption_type" {
  command = plan
  variables {
    encryption_type = "ConfidentialVmEncryptedWithCustomerKey"
  }
  assert {
    condition     = azurerm_disk_encryption_set.set.encryption_type == "ConfidentialVmEncryptedWithCustomerKey"
    error_message = "confidential VM encryption type should be accepted"
  }
}

run "rejects_platform_key_encryption_type" {
  command = plan
  variables {
    encryption_type = "EncryptionAtRestWithPlatformKey"
  }
  expect_failures = [var.encryption_type]
}

run "rejects_empty_name" {
  command = plan
  variables {
    name = ""
  }
  expect_failures = [var.name]
}

run "rejects_too_long_name" {
  command = plan
  variables {
    name = join("", [for i in range(81) : "a"])
  }
  expect_failures = [var.name]
}

run "rejects_name_with_invalid_character" {
  command = plan
  variables {
    name = "des.platform.prod"
  }
  expect_failures = [var.name]
}

run "rejects_empty_resource_group_name" {
  command = plan
  variables {
    resource_group_name = ""
  }
  expect_failures = [var.resource_group_name]
}

run "rejects_blank_location" {
  command = plan
  variables {
    location = " "
  }
  expect_failures = [var.location]
}

run "rejects_blank_key_vault_key_id" {
  command = plan
  variables {
    key_vault_key_id = ""
  }
  expect_failures = [var.key_vault_key_id]
}

run "rejects_blank_managed_hsm_key_id" {
  command = plan
  variables {
    key_vault_key_id   = null
    managed_hsm_key_id = " "
  }
  expect_failures = [var.managed_hsm_key_id]
}

run "rejects_invalid_federated_client_id" {
  command = plan
  variables {
    federated_client_id = "not-a-guid"
  }
  expect_failures = [var.federated_client_id]
}

run "accepts_federated_client_id" {
  command = plan
  variables {
    federated_client_id = "11111111-2222-3333-4444-555555555555"
  }
  assert {
    condition     = azurerm_disk_encryption_set.set.federated_client_id == "11111111-2222-3333-4444-555555555555"
    error_message = "federated_client_id should be wired"
  }
}

run "rejects_duplicate_identity_ids" {
  command = plan
  variables {
    identity_ids = [
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mi-des",
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mi-des"
    ]
  }
  expect_failures = [var.identity_ids]
}

run "rejects_blank_identity_ids" {
  command = plan
  variables {
    identity_ids = [" "]
  }
  expect_failures = [var.identity_ids]
}
