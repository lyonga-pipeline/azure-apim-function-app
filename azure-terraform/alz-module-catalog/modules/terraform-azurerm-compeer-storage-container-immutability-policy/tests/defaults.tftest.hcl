mock_provider "azurerm" {}
variables {
  storage_container_resource_manager_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-st/providers/Microsoft.Storage/storageAccounts/stimm/blobServices/default/containers/archive"
  immutability_period_in_days           = 30
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_storage_container_immutability_policy.this.immutability_period_in_days == 30
    error_message = "retention period not wired"
  }
}
