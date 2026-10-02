mock_provider "azurerm" {}
variables {
  name                = "id-platform-workload"
  resource_group_name = "rg-identity"
  location            = "eastus2"
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_user_assigned_identity.identity.name == "id-platform-workload"
    error_message = "name not wired"
  }
}

run "outputs_are_wired" {
  command = apply

  assert {
    condition = (
      output.id == azurerm_user_assigned_identity.identity.id &&
      output.name == azurerm_user_assigned_identity.identity.name &&
      output.client_id == azurerm_user_assigned_identity.identity.client_id &&
      output.principal_id == azurerm_user_assigned_identity.identity.principal_id &&
      output.tenant_id == azurerm_user_assigned_identity.identity.tenant_id
    )
    error_message = "every output must echo its corresponding resource attribute"
  }
}

run "accepts_boundary_length_names" {
  command = plan
  variables {
    name = "idx" # 3 chars, the documented minimum
  }
  assert {
    condition     = azurerm_user_assigned_identity.identity.name == "idx"
    error_message = "a 3-character name should be accepted"
  }
}

run "rejects_too_short_name" {
  command = plan
  variables {
    name = "id" # 2 chars, below the 3-char minimum
  }
  expect_failures = [var.name]
}

run "rejects_too_long_name" {
  command = plan
  variables {
    name = join("", [for i in range(129) : "a"]) # 129 chars, over the 128-char maximum
  }
  expect_failures = [var.name]
}

run "rejects_name_starting_with_hyphen" {
  command = plan
  variables {
    name = "-id-platform-workload"
  }
  expect_failures = [var.name]
}

run "rejects_name_with_invalid_character" {
  command = plan
  variables {
    name = "id.platform.workload" # periods are not allowed
  }
  expect_failures = [var.name]
}

run "rejects_empty_resource_group_name" {
  command = plan
  variables {
    resource_group_name = ""
  }
  expect_failures = [var.resource_group_name]
}

run "rejects_blank_location" {
  command = plan
  variables {
    location = " "
  }
  expect_failures = [var.location]
}
