mock_provider "azurerm" {}
variables {
  name                = "apim-platform"
  resource_group_name = "rg-apim"
  location            = "eastus2"
  publisher_name      = "Platform Team"
  publisher_email     = "platform@example.com"
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_api_management.this.name == "apim-platform"
    error_message = "name not wired"
  }
  assert {
    condition     = azurerm_api_management.this.sku_name == "Developer_1"
    error_message = "default sku not applied"
  }
}
run "rejects_bad_sku" {
  command = plan
  variables { sku_name = "Developer" }
  expect_failures = [var.sku_name]
}
run "rejects_vnet_without_config" {
  command = plan
  variables { virtual_network_type = "Internal" }
  expect_failures = [azurerm_api_management.this]
}
