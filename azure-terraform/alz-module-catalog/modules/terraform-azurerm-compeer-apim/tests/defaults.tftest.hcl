mock_provider "azurerm" {}

variables {
  name                = "apim-platform-test"
  resource_group_name = "rg-apim-test"
  location            = "eastus2"
  publisher_name      = "Platform Team"
  publisher_email     = "platform@example.com"
}

run "secure_defaults" {
  command = apply

  assert {
    condition     = azurerm_api_management.apim.public_network_access_enabled == false
    error_message = "public network access must default closed"
  }
  assert {
    condition     = azurerm_api_management.apim.virtual_network_type == "None"
    error_message = "default VNet type is None"
  }
  assert {
    condition     = one(azurerm_api_management.apim.security).frontend_tls10_enabled == false
    error_message = "TLS 1.0 frontend must be disabled by default"
  }
}

run "rejects_bad_sku" {
  command = plan
  variables {
    sku_name = "Ultra_9"
  }
  expect_failures = [var.sku_name]
}

run "rejects_internal_without_subnet" {
  command = plan
  variables {
    virtual_network_type = "Internal"
  }
  expect_failures = [azurerm_api_management.apim]
}

run "internal_with_subnet_ok" {
  command = plan
  variables {
    virtual_network_type = "Internal"
    virtual_network_configuration = {
      subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/apim"
    }
  }
}
