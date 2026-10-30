# PHASE2 EXISTING: SEC-08 cryptographic key rotation, not application secret rotation.
mock_provider "azurerm" {}
variables {
  key_vault_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/security-rg/providers/Microsoft.KeyVault/vaults/platform-kv"
}
run "cmk_rotation_policy_is_wired" {
  command = plan
  variables {
    keys = { cmk = {
      key_type = "RSA"
      key_size = 4096
      key_opts = ["wrapKey", "unwrapKey"]
      rotation_policy = {
        expire_after         = "P180D"
        notify_before_expiry = "P30D"
        automatic            = { time_after_creation = "P90D" }
      }
    } }
  }
  assert {
    condition     = azurerm_key_vault_key.key["cmk"].rotation_policy[0].automatic[0].time_after_creation == "P90D" && azurerm_key_vault_key.key["cmk"].rotation_policy[0].notify_before_expiry == "P30D"
    error_message = "Approved key rotation and notification timings must reach Key Vault."
  }
}
