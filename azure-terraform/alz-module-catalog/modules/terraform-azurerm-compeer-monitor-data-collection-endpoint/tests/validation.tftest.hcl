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

run "outputs_are_wired" {
  command = apply

  assert {
    condition = (
      output.id == azurerm_monitor_data_collection_endpoint.endpoint.id &&
      output.name == azurerm_monitor_data_collection_endpoint.endpoint.name &&
      output.immutable_id == azurerm_monitor_data_collection_endpoint.endpoint.immutable_id &&
      output.configuration_access_endpoint == azurerm_monitor_data_collection_endpoint.endpoint.configuration_access_endpoint &&
      output.logs_ingestion_endpoint == azurerm_monitor_data_collection_endpoint.endpoint.logs_ingestion_endpoint &&
      output.metrics_ingestion_endpoint == azurerm_monitor_data_collection_endpoint.endpoint.metrics_ingestion_endpoint
    )
    error_message = "every output must echo its corresponding resource attribute"
  }
}
