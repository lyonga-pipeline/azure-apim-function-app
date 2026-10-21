mock_provider "azurerm" {}
mock_provider "azurerm" { alias = "dns" }
mock_provider "time" {}
mock_provider "tfe" {}

variables { environment = "prod" }

run "disabled_adapter_has_no_spoke" {
  command = plan
  assert {
    condition     = output.spoke == null
    error_message = "The package must remain inert before approved application inputs are supplied."
  }
}

run "legacy_budget_enablement_is_not_silently_ignored" {
  command = plan
  variables {
    configuration = {
      enabled    = false
      operations = { budget = { enabled = true, amount = 1000 } }
    }
  }
  expect_failures = [var.configuration]
}

run "even_disabled_legacy_budget_inputs_must_be_removed" {
  command = plan
  variables {
    configuration = {
      enabled    = false
      operations = { budget = { enabled = false } }
    }
  }
  expect_failures = [var.configuration]
}
