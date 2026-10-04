mock_provider "azurerm" {}
variables {
  name                = "pip-agw-prod"
  resource_group_name = "rg-connectivity"
  location            = "eastus2"
}
run "standard_static_defaults" {
  command = apply
  assert {
    condition     = azurerm_public_ip.ip.sku == "Standard" && azurerm_public_ip.ip.allocation_method == "Static"
    error_message = "should default to Standard/Static"
  }
}
run "rejects_standard_dynamic" {
  command = plan
  variables { allocation_method = "Dynamic" }
  expect_failures = [azurerm_public_ip.ip]
}
run "rejects_bad_sku" {
  command = plan
  variables { sku = "Gold" }
  expect_failures = [var.sku]
}
run "rejects_bad_sku_tier" {
  command = plan
  variables { sku_tier = "Planetary" }
  expect_failures = [var.sku_tier]
}
run "rejects_bad_ip_version" {
  command = plan
  variables { ip_version = "IPv5" }
  expect_failures = [var.ip_version]
}
run "rejects_bad_idle_timeout" {
  command = plan
  variables { idle_timeout_in_minutes = 31 }
  expect_failures = [var.idle_timeout_in_minutes]
}
