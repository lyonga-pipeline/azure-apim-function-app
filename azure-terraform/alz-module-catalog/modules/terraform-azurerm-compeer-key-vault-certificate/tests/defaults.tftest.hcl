mock_provider "azurerm" {}
variables {
  key_vault_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv"
}
run "empty_is_noop" {
  command = plan
  assert {
    condition     = length(azurerm_key_vault_certificate.this) == 0
    error_message = "no certificates by default"
  }
}
