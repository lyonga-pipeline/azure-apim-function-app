mock_provider "azurerm" {}
variables {
  name                = "natgw-spoke"
  location            = "eastus2"
  resource_group_name = "rg-net"
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_nat_gateway.nat-gateway.sku_name == "Standard"
    error_message = "sku_name should default to Standard"
  }
}
run "rejects_bad_idle_timeout" {
  command = plan
  variables { idle_timeout_in_minutes = 999 }
  expect_failures = [var.idle_timeout_in_minutes]
}
