mock_provider "azurerm" {}

variables {
  name     = "rg-platform-connectivity-prod"
  location = "eastus2"
}

run "create" {
  command = apply
  assert {
    condition     = azurerm_resource_group.group.name == "rg-platform-connectivity-prod"
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

run "rejects_name_over_90_chars" {
  # Only the trailing-period side of the validation was tested; the
  # length/charset side was not.
  command = plan
  variables {
    name = join("", [for i in range(91) : "a"])
  }
  expect_failures = [var.name]
}

run "rejects_name_with_disallowed_character" {
  command = plan
  variables {
    name = "rg-bad*name"
  }
  expect_failures = [var.name]
}

run "outputs_are_wired" {
  command = apply

  assert {
    condition = (
      output.id == azurerm_resource_group.group.id &&
      output.name == azurerm_resource_group.group.name &&
      output.location == azurerm_resource_group.group.location
    )
    error_message = "every output must echo its corresponding resource attribute"
  }
}
