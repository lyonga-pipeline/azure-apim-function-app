mock_provider "azurerm" {}
variables {
  eventgrid_topic_name   = "egst-platform"
  resource_group_name    = "rg-events"
  location               = "eastus2"
  source_arm_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-events/providers/Microsoft.Storage/storageAccounts/stevents"
  topic_type             = "Microsoft.Storage.StorageAccounts"
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_eventgrid_system_topic.system_topic.name == "egst-platform"
    error_message = "system topic name not wired"
  }
  assert {
    condition     = azurerm_eventgrid_system_topic.system_topic.topic_type == "Microsoft.Storage.StorageAccounts"
    error_message = "topic_type not wired"
  }
}
