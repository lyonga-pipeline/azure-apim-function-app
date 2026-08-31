mock_provider "azurerm" {}

variables {
  name                      = "app-web-test"
  resource_group_name       = "rg-web-test"
  location                  = "eastus2"
  service_plan_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Web/serverFarms/plan"
  virtual_network_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/web"
}

run "secure_defaults" {
  command = apply

  assert {
    condition     = azurerm_linux_web_app.linux_web_app.public_network_access_enabled == false
    error_message = "public network access must default closed"
  }
  assert {
    condition     = length(azurerm_linux_web_app.linux_web_app.site_config) == 1
    error_message = "exactly one site_config block must render"
  }
}

run "connection_strings_keyed_by_name" {
  command = apply

  variables {
    connection_string = {
      sql = { type = "SQLAzure", value = "Server=..." }
    }
  }

  assert {
    condition     = one(azurerm_linux_web_app.linux_web_app.connection_string).name == "sql"
    error_message = "connection_string name should be the map key"
  }
}

run "rejects_empty_site_config" {
  command = plan
  variables {
    site_config = []
  }
  expect_failures = [var.site_config]
}
