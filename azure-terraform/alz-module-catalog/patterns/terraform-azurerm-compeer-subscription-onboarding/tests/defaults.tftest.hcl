mock_provider "azurerm" {}

variables {
  management_group_ids = {
    connectivity = "/providers/Microsoft.Management/managementGroups/connectivity"
    corp         = "corp"
  }
  baseline_role_assignments = {
    platform_ops = {
      role_definition_name = "Contributor"
      principal_id         = "11111111-1111-1111-1111-111111111111"
      principal_type       = "Group"
    }
    security_readers = {
      role_definition_name = "Reader"
      principal_id         = "22222222-2222-2222-2222-222222222222"
      principal_type       = "Group"
    }
  }
  subscriptions = {
    hub = {
      subscription_id             = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
      target_management_group_key = "connectivity"
    }
    app_alpha = {
      subscription_id             = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
      target_management_group_key = "corp"
      app_role_assignments = {
        team_owner = {
          role_definition_name = "Owner"
          principal_id         = "33333333-3333-3333-3333-333333333333"
          principal_type       = "Group"
        }
      }
    }
  }
}

run "places_and_assigns" {
  command = apply

  assert {
    condition     = azurerm_management_group_subscription_association.placement["hub"].subscription_id == "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
    error_message = "hub subscription not wired to its association"
  }
  assert {
    condition     = azurerm_management_group_subscription_association.placement["app_alpha"].management_group_id == "/providers/Microsoft.Management/managementGroups/corp"
    error_message = "bare MG name not normalized to a full ID"
  }
  # 2 subscriptions x 2 baseline entries = 4 baseline assignments
  assert {
    condition     = length(module.baseline_role_assignments.ids) == 4
    error_message = "baseline RBAC did not fan out across both subscriptions"
  }
  assert {
    condition     = length(module.app_role_assignments.ids) == 1
    error_message = "app-specific RBAC not applied"
  }
}

run "opt_out_of_baseline" {
  command = apply

  variables {
    subscriptions = {
      sandbox = {
        subscription_id             = "cccccccc-cccc-cccc-cccc-cccccccccccc"
        target_management_group_key = "corp"
        apply_baseline_rbac         = false
      }
    }
  }

  assert {
    condition     = length(module.baseline_role_assignments.ids) == 0
    error_message = "apply_baseline_rbac = false should skip baseline RBAC"
  }
}

run "rejects_unknown_mg_key" {
  command = plan

  variables {
    subscriptions = {
      orphan = {
        subscription_id             = "dddddddd-dddd-dddd-dddd-dddddddddddd"
        target_management_group_key = "does-not-exist"
      }
    }
  }

  expect_failures = [terraform_data.onboarding_contract]
}

run "rejects_bad_guid" {
  command = plan

  variables {
    subscriptions = {
      bad = {
        subscription_id             = "/subscriptions/eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee"
        target_management_group_key = "corp"
      }
    }
  }

  expect_failures = [var.subscriptions]
}
