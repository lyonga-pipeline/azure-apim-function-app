mock_provider "azurerm" {}

variables {
  name                          = "fn-win-test"
  resource_group_name           = "rg-web-test"
  location                      = "eastus2"
  service_plan_id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Web/serverFarms/plan"
  storage_account_name          = "fnwinteststorage"
  storage_uses_managed_identity = true
}

run "secure_defaults" {
  command = apply

  assert {
    condition     = azurerm_windows_function_app.windows_function_app.public_network_access_enabled == false
    error_message = "public network access must default closed"
  }
  assert {
    condition     = azurerm_windows_function_app.windows_function_app.https_only == true
    error_message = "https_only must default true"
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
    condition     = one(azurerm_windows_function_app.windows_function_app.connection_string).name == "sql"
    error_message = "connection_string name should be the map key"
  }
}

run "rejects_empty_site_config" {
  command = plan
  variables { site_config = [] }
  expect_failures = [var.site_config]
}
