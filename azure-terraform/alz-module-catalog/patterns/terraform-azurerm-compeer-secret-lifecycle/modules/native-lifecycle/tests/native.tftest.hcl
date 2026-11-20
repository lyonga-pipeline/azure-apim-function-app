mock_provider "azurerm" {}
variables { vault_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/workload-rg/providers/Microsoft.KeyVault/vaults/pilot-vault" }
run "empty_does_not_create_vault_objects" {
  command = plan
  assert {
    condition     = length(azurerm_key_vault_key.key) == 0 && length(azurerm_key_vault_certificate.certificate) == 0
    error_message = "Do not create unregistered key/certificate material."
  }
}
run "key_uses_native_rotation" {
  command = plan
  variables { keys = { data = { name = "data-key" } } }
  assert {
    condition     = azurerm_key_vault_key.key["data"].rotation_policy[0].automatic[0].time_after_creation == "P1Y"
    error_message = "Use native rotation; never disable old encryption keys generically."
  }
}
run "reject_unsupported_certificate_issuer" {
  command = plan
  variables { certificates = { tls = { name = "tls", issuer_name = "Unknown", subject = "CN=example.com", dns_names = ["example.com"], validity_months = 12 } } }
  expect_failures = [var.certificates]
}
