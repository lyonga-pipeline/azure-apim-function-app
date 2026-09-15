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

run "external_parent_hierarchy" {
  command = plan
  variables {
    management_groups = {
      alz      = { display_name = "ALZ", parent_management_group_id = "/providers/Microsoft.Management/managementGroups/tenant-root" }
      platform = { display_name = "Platform", parent_key = "alz" }
    }
  }
  assert {
    condition     = length(azurerm_management_group.root) == 1
    error_message = "alz (externally parented) should be a top-level/root group"
  }
  assert {
    condition     = azurerm_management_group.root["alz"].parent_management_group_id == "/providers/Microsoft.Management/managementGroups/tenant-root"
    error_message = "per-group parent_management_group_id should win over root_parent_management_group_id"
  }
  assert {
    condition     = length(azurerm_management_group.level_1) == 1
    error_message = "platform should be created as a child of the externally parented top-level group"
  }
}

run "root_parent_default_applies" {
  command = plan
  variables {
    root_parent_management_group_id = "/providers/Microsoft.Management/managementGroups/compeer-enterprise-mg"
    management_groups = {
      platform = { display_name = "Platform" }
    }
  }
  assert {
    condition     = azurerm_management_group.root["platform"].parent_management_group_id == "/providers/Microsoft.Management/managementGroups/compeer-enterprise-mg"
    error_message = "top-level groups without a per-group parent should use root_parent_management_group_id"
  }
}

run "full_supported_depth" {
  command = plan
  variables {
    management_groups = {
      root    = { display_name = "Root" }
      level_1 = { display_name = "Level 1", parent_key = "root" }
      level_2 = { display_name = "Level 2", parent_key = "level_1" }
      level_3 = { display_name = "Level 3", parent_key = "level_2" }
      level_4 = { display_name = "Level 4", parent_key = "level_3" }
      level_5 = { display_name = "Level 5", parent_key = "level_4" }
    }
  }
  assert {
    condition     = length(azurerm_management_group.level_5) == 1
    error_message = "the fifth child level should be supported"
  }
}

run "subscription_association" {
  command = plan
  variables {
    management_groups = {
      landing_zones = {
        display_name     = "Landing Zones"
        subscription_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000"]
      }
    }
  }
  assert {
    condition     = length(azurerm_management_group_subscription_association.this) == 1
    error_message = "subscription associations should be created from subscription_ids"
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

run "rejects_unknown_parent_key" {
  command = plan
  variables {
    management_groups = {
      platform = { parent_key = "plateform" }
    }
  }
  expect_failures = [var.management_groups]
}

run "rejects_self_parent_key" {
  command = plan
  variables {
    management_groups = {
      platform = { parent_key = "platform" }
    }
  }
  expect_failures = [var.management_groups]
}

run "rejects_unsupported_depth" {
  command = plan
  variables {
    management_groups = {
      root    = { display_name = "Root" }
      level_1 = { display_name = "Level 1", parent_key = "root" }
      level_2 = { display_name = "Level 2", parent_key = "level_1" }
      level_3 = { display_name = "Level 3", parent_key = "level_2" }
      level_4 = { display_name = "Level 4", parent_key = "level_3" }
      level_5 = { display_name = "Level 5", parent_key = "level_4" }
      level_6 = { display_name = "Level 6", parent_key = "level_5" }
    }
  }
  expect_failures = [var.management_groups]
}
