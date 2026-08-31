# Offline plan-mode tests. No cloud auth required.

mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-dns-test"

  zones = {
    "privatelink.vaultcore.azure.net" = {
      vnet_links = {
        hub = { virtual_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-hub" }
      }
    }
    "privatelink.blob.core.windows.net" = {}
  }

  tags = { environment = "test" }
}

run "create" {
  command = plan

  assert {
    condition     = length(azurerm_private_dns_zone.this) == 2
    error_message = "Expected two zones"
  }
  assert {
    condition     = azurerm_private_dns_zone.this["privatelink.blob.core.windows.net"].name == "privatelink.blob.core.windows.net"
    error_message = "Zone name must come from the map key"
  }
  assert {
    condition     = length(azurerm_private_dns_zone_virtual_network_link.this) == 1
    error_message = "Expected one VNet link"
  }
  assert {
    condition     = azurerm_private_dns_zone_virtual_network_link.this["privatelink.vaultcore.azure.net/hub"].registration_enabled == false
    error_message = "registration_enabled should default to false"
  }
}

run "add_zone_is_additive" {
  command = plan

  variables {
    zones = {
      "privatelink.vaultcore.azure.net"   = {}
      "privatelink.blob.core.windows.net" = {}
      "privatelink.database.windows.net"  = {}
    }
  }

  assert {
    condition     = length(azurerm_private_dns_zone.this) == 3
    error_message = "Adding a zone key adds exactly one zone"
  }
}

run "rejects_bad_zone_name" {
  command = plan

  variables {
    zones = { "not a dns name" = {} }
  }

  expect_failures = [var.zones]
}
