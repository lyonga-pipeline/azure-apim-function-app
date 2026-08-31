mock_provider "azurerm" {}
variables {
  name                = "pip-agw-prod"
  resource_group_name = "rg-connectivity"
  location            = "eastus2"
}
run "standard_static_defaults" {
  command = apply
  assert {
    condition     = azurerm_public_ip.this.sku == "Standard" && azurerm_public_ip.this.allocation_method == "Static"
    error_message = "should default to Standard/Static"
  }
}
run "rejects_standard_dynamic" {
  command = plan
  variables { allocation_method = "Dynamic" }
  expect_failures = [azurerm_public_ip.this]
}
run "rejects_bad_sku" {
  command = plan
  variables { sku = "Gold" }
  expect_failures = [var.sku]
}
