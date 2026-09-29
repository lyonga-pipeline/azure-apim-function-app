mock_provider "azurerm" {}

variables {
  name                       = "kv-diag"
  target_resource_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv"
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mgmt/providers/Microsoft.OperationalInsights/workspaces/law"
}

run "disabled_metric_is_excluded_from_the_rendered_block" {
  # metrics[*].enabled defaults to true and is filtered via `if
  # try(metric.enabled, true)` in the dynamic block's for_each - the
  # enabled = false exclusion path had never been exercised.
  command = apply
  variables {
    metrics = {
      wanted   = { category = "AllMetrics", enabled = true }
      unwanted = { category = "Transaction", enabled = false }
    }
  }

  assert {
    condition     = length(azurerm_monitor_diagnostic_setting.setting.enabled_metric) == 1
    error_message = "enabled = false metrics must be excluded from the rendered enabled_metric blocks"
  }
  assert {
    condition     = one(azurerm_monitor_diagnostic_setting.setting.enabled_metric).category == "AllMetrics"
    error_message = "the remaining enabled_metric block must be the enabled one, not the disabled one"
  }
}

run "rejects_log_with_neither_category_nor_group" {
  # Only the both-set branch of this validation had a test before this -
  # the other half (neither field set) was untested.
  command = plan
  variables {
    logs = { bad = {} }
  }
  expect_failures = [var.logs]
}

run "accepts_storage_account_destination" {
  # Every prior passing run only ever used log_analytics_workspace_id as
  # the destination - storage_account_id/eventhub_*/partner_solution_id
  # were never exercised even though the precondition explicitly allows
  # any one of the four.
  command = plan
  variables {
    log_analytics_workspace_id = null
    storage_account_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Storage/storageAccounts/stdiag"
    logs                       = { audit = { category_group = "audit" } }
  }

  assert {
    condition     = azurerm_monitor_diagnostic_setting.setting.storage_account_id != null
    error_message = "storage_account_id alone should satisfy the at-least-one-destination precondition"
  }
}

run "outputs_are_wired" {
  command = apply
  variables {
    logs = { audit = { category_group = "audit" } }
  }

  assert {
    condition     = output.id == azurerm_monitor_diagnostic_setting.setting.id && output.name == azurerm_monitor_diagnostic_setting.setting.name
    error_message = "id/name outputs must echo the resource"
  }
  assert {
    condition     = output.destinations.log_analytics_workspace_id == azurerm_monitor_diagnostic_setting.setting.log_analytics_workspace_id
    error_message = "destinations output must echo the correct underlying attribute"
  }
}
