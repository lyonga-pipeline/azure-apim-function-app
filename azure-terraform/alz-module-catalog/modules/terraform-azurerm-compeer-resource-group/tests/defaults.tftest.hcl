mock_provider "azurerm" {}

variables {
  resource_groups = {
    main = {
      name     = "platform-cus-prod-connectivity-rg"
      location = "eastus2"
      tags     = {}
    }
  }
}

run "create" {
  command = apply
  assert {
    condition     = azurerm_resource_group.groups["main"].name == "platform-cus-prod-connectivity-rg"
    error_message = "name not wired"
  }
}

run "rejects_trailing_period" {
  command = plan
  variables {
    resource_groups = {
      main = {
        name     = "orders-cus-prod-network-rg."
        location = "eastus2"
      }
    }
  }
  expect_failures = [var.resource_groups]
}

run "rejects_name_over_90_chars" {
  command = plan
  variables {
    resource_groups = {
      main = {
        name     = "orders-cus-prod-${join("", [for i in range(91) : "a"])}"
        location = "eastus2"
      }
    }
  }
  expect_failures = [var.resource_groups]
}

run "rejects_name_with_disallowed_character" {
  command = plan
  variables {
    resource_groups = {
      main = {
        name     = "orders-cus-prod-network*rg"
        location = "eastus2"
      }
    }
  }
  expect_failures = [var.resource_groups]
}

run "rejects_empty_resource_groups" {
  command = plan
  variables {
    resource_groups = {}
  }
  expect_failures = [var.resource_groups]
}

run "rejects_unstable_key" {
  command = plan
  variables {
    resource_groups = {
      "-bad" = {
        name     = "platform-cus-prod-connectivity-rg"
        location = "eastus2"
      }
    }
  }
  expect_failures = [var.resource_groups]
}

run "rejects_duplicate_names" {
  command = plan
  variables {
    resource_groups = {
      main = {
        name     = "platform-cus-prod-connectivity-rg"
        location = "eastus2"
      }
      duplicate = {
        name     = "PLATFORM-CUS-PROD-CONNECTIVITY-RG"
        location = "eastus2"
      }
    }
  }
  expect_failures = [var.resource_groups]
}

run "rejects_blank_location" {
  command = plan
  variables {
    resource_groups = {
      main = {
        name     = "platform-cus-prod-connectivity-rg"
        location = " "
      }
    }
  }
  expect_failures = [var.resource_groups]
}

run "creates_multiple_groups" {
  command = apply
  variables {
    resource_groups = {
      network = {
        name     = "platform-cus-prod-network-rg"
        location = "centralus"
      }
      backup = {
        name     = "platform-cus-prod-backup-rg"
        location = "centralus"
        tags     = { purpose = "backup" }
      }
    }
  }
  assert {
    condition = (
      azurerm_resource_group.groups["network"].name == "platform-cus-prod-network-rg" &&
      azurerm_resource_group.groups["backup"].tags.purpose == "backup"
    )
    error_message = "multiple resource groups should be keyed and wired"
  }
}

run "outputs_are_wired" {
  command = apply

  assert {
    condition = (
      output.id == azurerm_resource_group.groups["main"].id &&
      output.name == azurerm_resource_group.groups["main"].name &&
      output.location == azurerm_resource_group.groups["main"].location &&
      output.group_ids["main"] == azurerm_resource_group.groups["main"].id &&
      output.group_names["main"] == azurerm_resource_group.groups["main"].name &&
      output.group_locations["main"] == azurerm_resource_group.groups["main"].location
    )
    error_message = "outputs must echo their corresponding resource attributes"
  }
}
