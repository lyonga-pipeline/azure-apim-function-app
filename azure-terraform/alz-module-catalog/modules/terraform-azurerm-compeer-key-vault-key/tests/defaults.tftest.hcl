mock_provider "azurerm" {}
variables {
  key_vault_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv"
  keys         = { cmk = { key_type = "RSA", key_size = 4096, key_opts = ["wrapKey", "unwrapKey"] } }
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_key_vault_key.this["cmk"].key_type == "RSA"
    error_message = "key_type not wired"
  }
}
