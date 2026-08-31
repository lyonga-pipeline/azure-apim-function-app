mock_provider "azurerm" {}
variables {
  name  = "Platform Custom Reader"
  scope = "/subscriptions/00000000-0000-0000-0000-000000000000"
  permissions = {
    read = { actions = ["Microsoft.Resources/subscriptions/resourceGroups/read"] }
  }
}
run "create" {
  command = apply
  assert {
    condition     = length(azurerm_role_definition.this.permissions) == 1
    error_message = "expected one permissions block"
  }
}
run "rejects_no_permissions" {
  command = plan
  variables { permissions = {} }
  expect_failures = [var.permissions]
}
