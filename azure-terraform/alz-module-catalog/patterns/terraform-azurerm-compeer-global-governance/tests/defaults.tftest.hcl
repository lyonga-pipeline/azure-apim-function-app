mock_provider "azurerm" {}

variables {
  subscription_id          = "00000000-0000-0000-0000-000000000000"
  root_management_group_id = "tenant-root"
  management_groups = {
    enterprise = { display_name = "compeer-enterprise-mg", parent_key = "root" }
    platform   = { display_name = "platform-mg", parent_key = "enterprise" }
    workloads  = { display_name = "workloads-mg", parent_key = "enterprise" }
  }
}

run "mg_hierarchy" {
  command = plan
  assert {
    condition     = contains(keys(azurerm_management_group.root), "enterprise")
    error_message = "enterprise MG not at root"
  }
  assert {
    condition     = contains(keys(azurerm_management_group.level_1), "platform") && contains(keys(azurerm_management_group.level_1), "workloads")
    error_message = "platform/workloads not level 1"
  }
}

run "policy_baseline_off_by_default" {
  command = plan
  assert {
    condition     = length(local.pb_definitions) == 0 && length(local.pb_assignments) == 0
    error_message = "policy baseline should be inert unless enabled"
  }
}

run "policy_baseline_on" {
  command = plan
  variables {
    policy_baseline = {
      enabled              = true
      management_group_key = "enterprise"
      effect               = "Audit"
      allowed_locations    = ["centralus", "eastus2"]
    }
  }
  assert {
    condition     = length(local.pb_definitions) == 6
    error_message = "expected 6 baseline policy definitions"
  }
  assert {
    condition     = contains(keys(local.pb_assignments), "cmp-mcsb")
    error_message = "MCSB initiative assignment missing"
  }
  assert {
    condition     = local.pb_assignments["cmp-allowed-locations"].parameters.effect.value == "Audit"
    error_message = "baseline should assign in Audit by default"
  }
  assert {
    condition     = contains(keys(azurerm_policy_definition.this), "cmp-required-tags")
    error_message = "baseline definitions not merged into the pattern's for_each"
  }
}

run "policy_baseline_requires_mg_key" {
  command = plan
  variables {
    policy_baseline = { enabled = true }
  }
  expect_failures = [var.policy_baseline]
}
