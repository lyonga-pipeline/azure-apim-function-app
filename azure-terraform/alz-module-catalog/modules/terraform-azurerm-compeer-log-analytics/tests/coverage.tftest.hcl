mock_provider "azurerm" {}

variables {
  log_analytics_workspace_name    = "law-platform"
  resource_group_name             = "rg-mgmt"
  location                        = "eastus2"
  log_analytics_sku               = "PerGB2018"
  log_analytics_retention_in_days = 90
}

run "outputs_are_wired" {
  command = apply

  assert {
    condition     = output.id == azurerm_log_analytics_workspace.logs.id && output.resource_id == azurerm_log_analytics_workspace.logs.id
    error_message = "id/resource_id outputs must echo the resource"
  }
  assert {
    condition     = output.workspace_id == azurerm_log_analytics_workspace.logs.workspace_id
    error_message = "workspace_id output must echo the resource's own workspace_id (a GUID), not id"
  }
  assert {
    condition     = output.identity_principal_id == null
    error_message = "identity_principal_id must be null when no identity is configured"
  }
}

run "identity_dynamic_block_wired_to_output" {
  # Never previously tested at all.
  command = apply
  variables {
    identity = { type = "SystemAssigned" }
  }

  assert {
    condition     = output.identity_principal_id == azurerm_log_analytics_workspace.logs.identity[0].principal_id
    error_message = "identity_principal_id output must echo the resource's identity block"
  }
}

run "rejects_free_tier_retention_of_7_days" {
  # This module's validation used to have a "== 7 (Free tier)" exception
  # that let a value through the variable's own check even though the real
  # azurerm_log_analytics_workspace resource has always rejected anything
  # outside 30-730 (the Free SKU is deprecated, confirmed against the
  # current provider docs) - writing this test caught the stale exception
  # actually erroring at the resource, so the validation was corrected to
  # match reality instead of the test being adjusted to match the bug.
  command = plan
  variables {
    log_analytics_retention_in_days = 7
  }
  expect_failures = [var.log_analytics_retention_in_days]
}

run "rejects_retention_between_7_and_30" {
  command = plan
  variables {
    log_analytics_retention_in_days = 15
  }
  expect_failures = [var.log_analytics_retention_in_days]
}

run "accepts_retention_boundary_values" {
  command = plan
  variables {
    log_analytics_retention_in_days = 30
  }

  assert {
    condition     = azurerm_log_analytics_workspace.logs.retention_in_days == 30
    error_message = "the lower boundary of the 30-730 range should be accepted"
  }
}
