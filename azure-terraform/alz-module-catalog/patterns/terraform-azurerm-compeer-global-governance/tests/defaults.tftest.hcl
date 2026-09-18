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
    condition     = contains(keys(local.policy_definitions_input), "cmp-required-tags")
    error_message = "baseline definitions not merged into the module's policy_definitions input"
  }
  assert {
    # Regression: cmp-required-tags must audit the tags
    # terraform-azurerm-compeer-platform-tags' mandatory_keys actually emits
    # today (environment/owner/created_on/...), not the pre-Phase-7 names
    # (env/bt_owner/tf_workspace/recovery/compliance_boundary) that module was
    # renamed away from - that mismatch made every correctly-tagged resource
    # fail the guardrail.
    condition = sort(local.pb_required_tags) == sort([
      "environment", "application", "appcode", "owner", "source_repo", "created_on",
      "criticality_tier", "data_classification", "lifecycle_state",
      "cost_center", "gl_category",
    ])
    error_message = "cmp-required-tags default list has drifted from platform-tags' mandatory_keys"
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
    condition     = contains(keys(local.policy_set_definitions_input), "compeer-landing-zone-baseline")
    error_message = "baseline initiative not merged into the module's policy_set_definitions input"
  }
  assert {
    # exactly 2 assignments now: the one bundled initiative + MCSB - not 7
    condition     = length(local.management_group_policy_assignments_input) == 2
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
