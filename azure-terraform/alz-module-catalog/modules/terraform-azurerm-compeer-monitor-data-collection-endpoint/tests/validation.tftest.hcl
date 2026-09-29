mock_provider "azurerm" {}

variables {
  name                = "dce-platform"
  resource_group_name = "rg-mon"
  location            = "eastus2"
}

run "accepts_valid_kind" {
  command = plan
  variables {
    kind = "Linux"
  }
  assert {
    condition     = azurerm_monitor_data_collection_endpoint.endpoint.kind == "Linux"
    error_message = "valid kind should be accepted"
  }
}

run "rejects_bad_kind" {
  command = plan
  variables {
    kind = "MacOS"
  }
  expect_failures = [var.kind]
}
