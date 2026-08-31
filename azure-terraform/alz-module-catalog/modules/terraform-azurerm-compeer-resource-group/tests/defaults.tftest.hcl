mock_provider "azurerm" {}

variables {
  name     = "rg-platform-connectivity-prod"
  location = "eastus2"
}

run "create" {
  command = apply
  assert {
    condition     = azurerm_resource_group.this.name == "rg-platform-connectivity-prod"
    error_message = "name not wired"
  }
}

run "rejects_trailing_period" {
  command = plan
  variables {
    name = "rg-bad."
  }
  expect_failures = [var.name]
}
