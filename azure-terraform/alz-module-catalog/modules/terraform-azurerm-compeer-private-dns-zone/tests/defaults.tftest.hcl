mock_provider "azurerm" {}
variables {
  zones = {
    kv   = { name = "privatelink.vaultcore.azure.net", resource_group_name = "rg-dns" }
    blob = { name = "privatelink.blob.core.windows.net", resource_group_name = "rg-dns" }
  }
}
run "create" {
  command = apply
  assert {
    condition     = length(azurerm_private_dns_zone.this) == 2
    error_message = "expected two zones"
  }
  assert {
    condition     = azurerm_private_dns_zone.this["kv"].name == "privatelink.vaultcore.azure.net"
    error_message = "zone name from map value"
  }
}
run "rejects_bad_zone_name" {
  command = plan
  variables { zones = { x = { name = "not a zone", resource_group_name = "rg" } } }
  expect_failures = [var.zones]
}
