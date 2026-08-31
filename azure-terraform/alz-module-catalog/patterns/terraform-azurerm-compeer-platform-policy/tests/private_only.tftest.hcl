mock_provider "azurerm" {}

variables {
  subscription_id = "00000000-0000-0000-0000-000000000000"
  management_group_ids = {
    platform = "/providers/Microsoft.Management/managementGroups/platform"
    corp     = "/providers/Microsoft.Management/managementGroups/corp"
  }
}

run "baseline_off_by_default" {
  command = plan

  assert {
    condition     = length(local.poc_definitions) == 0 && length(local.poc_set_definitions) == 0 && length(local.poc_assignments) == 0
    error_message = "private-only baseline should be inert when not enabled"
  }
}

run "baseline_on_creates_defs_initiative_assignment" {
  command = plan

  variables {
    private_only_connectivity = {
      enabled                                = true
      management_group_key                   = "corp"
      effect                                 = "Audit"
      allowed_public_ip_resource_group_names = ["rg-edge-palo", "rg-edge-bastion", "rg-hybrid-gateway"]
    }
  }

  assert {
    condition     = length(local.poc_definitions) == 2 && contains(keys(local.poc_definitions), "deny-public-ip-address") && contains(keys(local.poc_definitions), "deny-nic-public-ip")
    error_message = "both custom deny definitions should be generated"
  }
  assert {
    condition     = contains(keys(local.poc_set_definitions), "compeer-private-only-connectivity")
    error_message = "private-only initiative not generated"
  }
  assert {
    condition     = local.poc_assignments["compeer-private-only-connectivity"].policy_set_definition_key == "compeer-private-only-connectivity"
    error_message = "assignment does not reference the generated initiative"
  }
  assert {
    condition     = local.poc_assignments["compeer-private-only-connectivity"].parameters.allowedResourceGroupNames.value == tolist(["rg-edge-palo", "rg-edge-bastion", "rg-hybrid-gateway"])
    error_message = "allow-list not passed to the assignment"
  }
  assert {
    condition     = contains(keys(azurerm_policy_definition.this), "deny-public-ip-address")
    error_message = "custom definition not merged into the pattern's for_each"
  }
}

run "rejects_bad_effect" {
  command = plan

  variables {
    private_only_connectivity = {
      enabled              = true
      management_group_key = "corp"
      effect               = "Block"
    }
  }

  expect_failures = [var.private_only_connectivity]
}

run "rejects_missing_scope" {
  command = plan

  variables {
    private_only_connectivity = {
      enabled = true
    }
  }

  expect_failures = [var.private_only_connectivity]
}
