mock_provider "azurerm" {}
variables {
  key_vault_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv"
  secrets      = { db-pw = { value = "s3cr3t" } }
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_key_vault_secret.this["db-pw"].name == "db-pw"
    error_message = "secret name should default to the map key"
  }
}
run "empty_is_noop" {
  command = plan
  variables { secrets = {} }
  assert {
    condition     = length(azurerm_key_vault_secret.this) == 0
    error_message = "no secrets by default"
  }
}
