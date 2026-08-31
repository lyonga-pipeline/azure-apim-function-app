mock_provider "azurerm" {}

run "empty_is_noop" {
  command = plan
  assert {
    condition     = length(azurerm_management_group.root) == 0 && length(azurerm_management_group.level_1) == 0
    error_message = "no management groups by default"
  }
}

run "two_level_hierarchy" {
  command = plan
  variables {
    management_groups = {
      platform = { display_name = "Platform" }
      identity = { display_name = "Identity", parent_key = "platform" }
    }
  }
  assert {
    condition     = length(azurerm_management_group.root) == 1
    error_message = "platform should be a root group"
  }
  assert {
    condition     = length(azurerm_management_group.level_1) == 1
    error_message = "identity should be a level-1 group"
  }
}

run "rejects_two_parent_specifiers" {
  command = plan
  variables {
    management_groups = {
      x = { parent_key = "a", parent_management_group_id = "/providers/Microsoft.Management/managementGroups/b" }
    }
  }
  expect_failures = [var.management_groups]
}
