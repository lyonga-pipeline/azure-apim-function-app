mock_provider "azurerm" {}
variables {
  eventgrid_topic_name = "egt-platform"
  resource_group_name  = "rg-events"
  location             = "eastus2"
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_eventgrid_topic.main.name == "egt-platform"
    error_message = "topic name not wired"
  }
}
