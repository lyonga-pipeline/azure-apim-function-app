mock_provider "azurerm" {}
variables {
  name                          = "phase2archivereference"
  resource_group_name           = "archive-rg"
  location                      = "centralus"
  public_network_access_enabled = true
  network_rules                 = { default_action = "Deny", bypass = ["AzureServices"] }
}
run "legacy_trusted_only_network_still_requires_approval" {
  command         = plan
  expect_failures = [azurerm_storage_account.account]
}
run "approved_monitoring_export_exception_is_narrow" {
  command = plan
  variables { trusted_service_only_access_approved = true }
  assert {
    condition     = azurerm_storage_account.account.network_rules[0].default_action == "Deny" && !azurerm_storage_account.account.shared_access_key_enabled && !azurerm_storage_account.account.allow_nested_items_to_be_public
    error_message = "Trusted-service approval must not grant Allow-all, shared keys or anonymous blobs."
  }
}
run "approval_does_not_allow_all_networks" {
  command = plan
  variables {
    trusted_service_only_access_approved = true
    network_rules                        = { default_action = "Allow" }
  }
  expect_failures = [azurerm_storage_account.account]
}
