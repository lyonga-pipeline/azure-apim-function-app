mock_provider "azurerm" {}

variables {
  subscription_id          = "00000000-0000-0000-0000-000000000000"
  root_management_group_id = "tenant-root"
  management_groups = {
    "compeer-enterprise-mg" = { parent_key = "root" }
    "platform-mg"           = { parent_key = "compeer-enterprise-mg" }
    "workloads-mg"          = { parent_key = "compeer-enterprise-mg" }
  }
}

run "mg_hierarchy" {
  command = plan
  assert {
    condition = alltrue([
      for key in ["compeer-enterprise-mg", "platform-mg", "workloads-mg"] :
      contains(keys(output.management_group_ids), key)
    ])
    error_message = "management-groups module did not surface every hierarchy key"
  }
  assert {
    condition     = contains(keys(local.management_group_scope_ids), "root")
    error_message = "root sentinel scope missing from management_group_scope_ids"
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
      management_group_key = "compeer-enterprise-mg"
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
    condition     = local.pb_assignments["cmp-landing-zone-baseline"].parameters.effect.value == "Audit"
    error_message = "baseline should assign in Audit by default"
  }
  assert {
    condition     = contains(keys(azurerm_policy_definition.definition), "cmp-required-tags")
    error_message = "baseline definitions not merged into the pattern's for_each"
  }
}

run "policy_baseline_packages_into_one_initiative" {
  command = plan
  variables {
    policy_baseline = {
      enabled              = true
      management_group_key = "compeer-enterprise-mg"
    }
  }
  assert {
    condition     = length(local.pb_initiative) == 1
    error_message = "expected the 6 baseline policies to package into exactly one initiative"
  }
  assert {
    condition     = length(local.pb_initiative["compeer-landing-zone-baseline"].policy_definition_references) == 6
    error_message = "expected the initiative to reference all 6 baseline policy definitions"
  }
  assert {
    condition     = contains(keys(azurerm_policy_set_definition.initiative), "compeer-landing-zone-baseline")
    error_message = "baseline initiative not merged into the pattern's azurerm_policy_set_definition.initiative for_each"
  }
  assert {
    # exactly 2 assignments now: the one bundled initiative + MCSB - not 7
    condition     = length(azurerm_management_group_policy_assignment.mg_assignment) == 2
    error_message = "expected the 6 individual baseline assignments to collapse into 1 initiative assignment (+ MCSB)"
  }
  assert {
    condition     = local.pb_assignments["cmp-landing-zone-baseline"].policy_set_definition_key == local.pb_initiative_key
    error_message = "the baseline assignment should point at the packaged initiative by key, not at an individual policy"
  }
}

run "policy_baseline_requires_mg_key" {
  command = plan
  variables {
    policy_baseline = { enabled = true }
  }
  expect_failures = [var.policy_baseline]
}
