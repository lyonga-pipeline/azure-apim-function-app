mock_provider "azurerm" {}
run "empty_is_noop" {
  command = plan
  assert {
    condition     = length(azurerm_management_lock.this) == 0
    error_message = "no locks by default"
  }
}
run "creates_locks" {
  command = apply
  variables {
    locks = {
      rg-prod = { name = "no-delete", scope = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-prod", lock_level = "CanNotDelete" }
    }
  }
  assert {
    condition     = azurerm_management_lock.this["rg-prod"].lock_level == "CanNotDelete"
    error_message = "lock level not wired"
  }
}
