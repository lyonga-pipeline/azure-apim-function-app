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
    condition     = length(azurerm_subnet.this) == 2
    error_message = "expected two subnets"
  }
  assert {
    condition     = azurerm_subnet.this["app"].name == "app"
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
    condition     = length(azurerm_subnet.this) == 3
    error_message = "adding a key adds one subnet"
  }
}
run "rejects_empty_address_space" {
  command = plan
  variables { address_space = [] }
  expect_failures = [var.address_space]
}
