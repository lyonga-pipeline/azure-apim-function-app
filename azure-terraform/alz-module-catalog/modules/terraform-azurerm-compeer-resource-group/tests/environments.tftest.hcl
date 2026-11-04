mock_provider "azurerm" {}

run "all_spoke_and_legacy_environments_are_supported" {
  command = apply
  variables {
    resource_groups = {
      for environment in ["prod", "dev", "test", "uat", "np0", "np1", "np2", "np3", "dev-test", "sandbox", "sbx"] : environment => {
        name = "orders-cus-${environment}-network-rg", location = "centralus", tags = { environment = environment }
      }
    }
  }
  assert {
    condition = (
      length(azurerm_resource_group.groups) == 11 &&
      alltrue([for key, group in var.resource_groups :
        output.group_names[key] == group.name &&
        output.group_ids[key] == azurerm_resource_group.groups[key].id &&
        azurerm_resource_group.groups[key].tags == group.tags
      ])
    )
    error_message = "Environment support must preserve each caller-owned key, name, tags and real resource identity."
  }
}

run "northcentral_and_case_insensitive_convention_remain_supported" {
  command = plan
  variables {
    resource_groups = {
      main = { name = "ORDERS-NCUS-UAT-NETWORK-RG", location = "northcentralus" }
    }
  }
  assert {
    condition     = output.group_names.main == "ORDERS-NCUS-UAT-NETWORK-RG"
    error_message = "Validation must accept the existing ncus/case policy without rewriting caller names."
  }
}

run "unapproved_environment_is_rejected" {
  command = plan
  variables {
    resource_groups = {
      main = { name = "orders-cus-qa-network-rg", location = "centralus" }
    }
  }
  expect_failures = [var.resource_groups]
}

run "unapproved_region_is_rejected" {
  command = plan
  variables {
    resource_groups = {
      main = { name = "orders-eus-prod-network-rg", location = "eastus" }
    }
  }
  expect_failures = [var.resource_groups]
}

run "environment_prefix_is_not_a_valid_environment" {
  command = plan
  variables {
    resource_groups = {
      main = { name = "orders-cus-sandboxed-network-rg", location = "centralus" }
    }
  }
  expect_failures = [var.resource_groups]
}

run "region_prefix_is_not_a_valid_region" {
  command = plan
  variables {
    resource_groups = {
      main = { name = "orders-xcus-prod-network-rg", location = "centralus" }
    }
  }
  expect_failures = [var.resource_groups]
}
