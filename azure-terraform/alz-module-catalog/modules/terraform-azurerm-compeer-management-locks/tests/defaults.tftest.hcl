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

run "rejects_invalid_lock_level" {
  command = plan
  variables {
    locks = {
      rg-prod = { scope = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-prod", lock_level = "DeleteOnly" }
    }
  }
  expect_failures = [var.locks]
}

run "rejects_empty_scope" {
  command = plan
  variables {
    locks = {
      rg-prod = { scope = "", lock_level = "CanNotDelete" }
    }
  }
  expect_failures = [var.locks]
}
