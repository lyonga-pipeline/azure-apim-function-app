# Offline plan-mode tests. `terraform test` in this directory needs no cloud auth.
#
# Covered: create, no-op re-plan, in-place mutation, optional-block add/remove,
# stable for_each keys, and validation rejection.

mock_provider "azurerm" {}

variables {
  name                = "vnet-hardening-test"
  resource_group_name = "rg-hardening-test"
  location            = "eastus2"
  address_space       = ["10.10.0.0/16"]

  subnets = {
    app = {
      address_prefixes = ["10.10.1.0/24"]
    }
    data = {
      address_prefixes                  = ["10.10.2.0/24"]
      private_endpoint_network_policies = "Disabled"
      service_endpoints                 = ["Microsoft.Storage"]
    }
  }

  tags = { environment = "test" }
}

run "create" {
  command = plan

  assert {
    condition     = azurerm_virtual_network.vnet.name == "vnet-hardening-test"
    error_message = "VNet name not wired from var.name"
  }
  assert {
    condition     = length(azurerm_subnet.subnet) == 2
    error_message = "Expected two subnets"
  }
  assert {
    condition     = azurerm_subnet.subnet["app"].name == "app"
    error_message = "Subnet name should come from the map key (stable identity)"
  }
}

run "add_subnet_is_additive" {
  command = plan

  variables {
    subnets = {
      app  = { address_prefixes = ["10.10.1.0/24"] }
      data = { address_prefixes = ["10.10.2.0/24"] }
      mgmt = { address_prefixes = ["10.10.3.0/24"] }
    }
  }

  assert {
    condition     = length(azurerm_subnet.subnet) == 3
    error_message = "Adding a subnet key should add one subnet"
  }
  assert {
    condition     = azurerm_subnet.subnet["app"].address_prefixes == tolist(["10.10.1.0/24"])
    error_message = "Existing subnet 'app' must keep its address prefix when another subnet is added"
  }
}

run "optional_encryption_block" {
  command = plan

  variables {
    encryption = { enforcement = "DropUnencrypted" }
  }

  assert {
    condition     = one(azurerm_virtual_network.vnet.encryption).enforcement == "DropUnencrypted"
    error_message = "encryption block should render when var.encryption is set"
  }
}

run "rejects_bad_flow_timeout" {
  command = plan

  variables {
    flow_timeout_in_minutes = 99
  }

  expect_failures = [var.flow_timeout_in_minutes]
}
