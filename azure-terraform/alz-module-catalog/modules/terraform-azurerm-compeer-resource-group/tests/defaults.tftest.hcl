mock_provider "azurerm" {}

variables {
  resource_groups = {
    main = {
      name     = "rg-platform-connectivity-prod"
      location = "eastus2"
      tags     = {}
    }
  }
}

run "create" {
  command = apply
  assert {
    condition     = azurerm_resource_group.groups["main"].name == "rg-platform-connectivity-prod"
    error_message = "name not wired"
  }
}

run "rejects_trailing_period" {
  command = plan
  variables {
    resource_groups = {
      main = {
        name     = "rg-bad."
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
        name     = join("", [for i in range(91) : "a"])
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
        name     = "rg-bad*name"
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
        name     = "rg-platform-connectivity-prod"
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
        name     = "rg-platform-connectivity-prod"
        location = "eastus2"
      }
      duplicate = {
        name     = "RG-PLATFORM-CONNECTIVITY-PROD"
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
        name     = "rg-platform-connectivity-prod"
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
        name     = "rg-platform-network-prod"
        location = "centralus"
      }
      backup = {
        name     = "rg-platform-backup-prod"
        location = "centralus"
        tags     = { purpose = "backup" }
      }
    }
  }
  assert {
    condition = (
      azurerm_resource_group.groups["network"].name == "rg-platform-network-prod" &&
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
