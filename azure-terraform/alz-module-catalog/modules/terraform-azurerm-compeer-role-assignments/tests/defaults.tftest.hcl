mock_provider "azurerm" {}

variables {
  assignments = {
    workload-kv-reader = {
      scope                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv"
      principal_id         = "11111111-1111-1111-1111-111111111111"
      role_definition_name = "Key Vault Secrets User"
    }
    subscription-reader = {
      scope              = "/subscriptions/00000000-0000-0000-0000-000000000000"
      principal_id       = "22222222-2222-2222-2222-222222222222"
      role_definition_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
    }
  }
}

run "create" {
  command = apply

  assert {
    condition     = length(azurerm_role_assignment.this) == 2
    error_message = "expected two role assignments"
  }
  assert {
    condition     = azurerm_role_assignment.this["workload-kv-reader"].scope == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv"
    error_message = "scope wired from the map value"
  }
}

run "add_assignment_is_additive" {
  command = apply

  variables {
    assignments = {
      workload-kv-reader = {
        scope                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv"
        principal_id         = "11111111-1111-1111-1111-111111111111"
        role_definition_name = "Key Vault Secrets User"
      }
      subscription-reader = {
        scope              = "/subscriptions/00000000-0000-0000-0000-000000000000"
        principal_id       = "22222222-2222-2222-2222-222222222222"
        role_definition_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
      }
      new-owner = {
        scope                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg"
        principal_id         = "33333333-3333-3333-3333-333333333333"
        role_definition_name = "Owner"
      }
    }
  }

  assert {
    condition     = length(azurerm_role_assignment.this) == 3
    error_message = "adding an assignment key adds exactly one assignment"
  }
}

run "rejects_both_name_and_id" {
  command = plan

  variables {
    assignments = {
      bad = {
        scope                = "/subscriptions/00000000-0000-0000-0000-000000000000"
        principal_id         = "44444444-4444-4444-4444-444444444444"
        role_definition_name = "Reader"
        role_definition_id   = "/subscriptions/x/providers/Microsoft.Authorization/roleDefinitions/y"
      }
    }
  }

  expect_failures = [var.assignments]
}
