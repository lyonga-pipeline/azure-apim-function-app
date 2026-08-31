mock_provider "azurerm" {}

variables {
  name               = "managedsa"
  key_vault_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv"
  storage_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Storage/storageAccounts/sa"
}

run "defaults" {
  command = apply

  assert {
    condition     = azurerm_key_vault_managed_storage_account.this.storage_account_key == "key1"
    error_message = "default managed key should be key1"
  }
  assert {
    condition     = azurerm_key_vault_managed_storage_account.this.regenerate_key_automatically == true
    error_message = "auto key regeneration should default on"
  }
  assert {
    condition     = length(azurerm_key_vault_managed_storage_account_sas_token_definition.this) == 0
    error_message = "no SAS definitions by default"
  }
}

# Note: azurerm_key_vault_managed_storage_account_sas_token_definition does
# client-side ID parsing on managed_storage_account_id at plan time, which the
# mock provider cannot satisfy — so the SAS path is covered by validate only.

run "rejects_bad_key" {
  command = plan
  variables {
    storage_account_key = "key3"
  }
  expect_failures = [var.storage_account_key]
}
