mock_provider "azurerm" {}

variables {
  name                = "des-platform-prod"
  resource_group_name = "rg-platform-security-prod"
  location            = "centralus"
  key_vault_key_id    = "https://kv-platform-prod.vault.azure.net/keys/des-key/abc123"
}

run "creates_with_key_vault_key" {
  command = plan
  assert {
    condition     = azurerm_disk_encryption_set.this.encryption_type == "EncryptionAtRestWithCustomerKey"
    error_message = "default encryption_type should be EncryptionAtRestWithCustomerKey"
  }
}

run "rejects_no_key_source" {
  command = plan
  variables {
    key_vault_key_id = null
  }
  expect_failures = [azurerm_disk_encryption_set.this]
}

run "rejects_both_key_sources" {
  command = plan
  variables {
    managed_hsm_key_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.KeyVault/managedHSMs/hsm1/keys/key1"
  }
  expect_failures = [azurerm_disk_encryption_set.this]
}

run "rejects_user_assigned_without_identity_ids" {
  command = plan
  variables {
    identity_type = "UserAssigned"
  }
  expect_failures = [azurerm_disk_encryption_set.this]
}

run "user_assigned_identity" {
  command = plan
  variables {
    identity_type = "UserAssigned"
    identity_ids  = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mi-des"]
  }
  assert {
    condition     = azurerm_disk_encryption_set.this.identity[0].type == "UserAssigned"
    error_message = "identity type should be UserAssigned"
  }
}
