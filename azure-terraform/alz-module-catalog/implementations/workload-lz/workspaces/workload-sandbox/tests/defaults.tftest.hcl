mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      subscription_id = "11111111-1111-1111-1111-111111111111"
      tenant_id       = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
    }
  }
}
mock_provider "azurerm" {
  alias = "dns"
  mock_data "azurerm_client_config" {
    defaults = {
      subscription_id = "33333333-3333-3333-3333-333333333333"
      tenant_id       = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
    }
  }
}
run "synthetic_example_is_disabled" {
  command = plan
  assert {
    condition     = length(module.blueprint) == 0
    error_message = "Synthetic values must not deploy a landing zone."
  }
}
run "approved_root_composes_the_real_blueprint" {
  command = plan
  variables {
    enabled             = true
    deployment_approved = true
  }
  assert {
    condition     = length(module.blueprint) == 1
    error_message = "Each environment must directly compose the blueprint with its own provider/state boundary."
  }
}
run "enabled_root_requires_explicit_approval" {
  command = plan
  variables { enabled = true }
  expect_failures = [terraform_data.approval]
}
