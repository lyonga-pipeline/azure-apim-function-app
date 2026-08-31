mock_provider "azurerm" {}
variables {
  storage_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-st/providers/Microsoft.Storage/storageAccounts/stlifecycle"
  rules = {
    cool-then-delete = {
      name    = "cool-then-delete"
      enabled = true
      filters = {
        prefix_match = ["logs/"]
        blob_types   = ["blockBlob"]
      }
      actions = {
        base_blob = {
          tier_to_cool_after_days_since_modification_greater_than = 30
          delete_after_days_since_modification_greater_than       = 365
        }
      }
    }
  }
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_storage_management_policy.this.storage_account_id == var.storage_account_id
    error_message = "storage_account_id not wired"
  }
}
