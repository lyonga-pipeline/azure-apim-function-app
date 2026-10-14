mock_provider "azurerm" {}
variables {
  name                = "vnet-spoke"
  resource_group_name = "rg-net"
  location            = "eastus2"
  address_space       = ["10.20.0.0/16"]
  subnets = {
    app  = { address_prefixes = ["10.20.1.0/24"] }
    data = { address_prefixes = ["10.20.2.0/24"], private_endpoint_network_policies = "Disabled" }
  }
}
run "create" {
  command = apply
  assert {
    condition     = length(azurerm_subnet.subnet) == 2
    error_message = "expected two subnets"
  }
  assert {
    condition     = azurerm_subnet.subnet["app"].name == "app"
    error_message = "subnet name = map key"
  }
}
run "add_subnet_is_additive" {
  command = apply
  variables {
    subnets = {
      app  = { address_prefixes = ["10.20.1.0/24"] }
      data = { address_prefixes = ["10.20.2.0/24"] }
      mgmt = { address_prefixes = ["10.20.3.0/24"] }
    }
  }
  assert {
    condition     = length(azurerm_subnet.subnet) == 3
    error_message = "adding a key adds one subnet"
  }
}
run "rejects_empty_address_space" {
  command = plan
  variables { address_space = [] }
  expect_failures = [var.address_space]
}

run "subnet_contract_reports_observed_private_defaults" {
  command = plan
  variables {
    subnets = {
      private_endpoints = { address_prefixes = ["10.20.3.0/27"], default_outbound_access_enabled = false, private_endpoint_network_policies = "Enabled" }
    }
  }
  assert {
    condition     = !output.subnets.private_endpoints.default_outbound_access_enabled && output.subnets.private_endpoints.private_endpoint_network_policies == "Enabled"
    error_message = "Subnet security output fields must reflect actual Azure resource configuration, not desired constants."
  }
}
