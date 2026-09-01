mock_provider "azurerm" {}
variables {
  name                = "stplatform001"
  resource_group_name = "rg-storage"
  location            = "eastus2"
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_storage_account.this.name == "stplatform001"
    error_message = "name not wired"
  }
}
run "no_op_replan" {
  command = plan
}

run "public_requires_firewall_allowlist" {
  command = plan
  variables {
    public_network_access_enabled = true
    network_rules                 = { default_action = "Deny" } # no allow-list
  }
  expect_failures = [azurerm_storage_account.this]
}

run "public_with_service_endpoint_ok" {
  command = plan
  variables {
    public_network_access_enabled = true
    network_rules = {
      default_action             = "Deny"
      virtual_network_subnet_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet/subnets/palo-mgmt"]
    }
  }
}
