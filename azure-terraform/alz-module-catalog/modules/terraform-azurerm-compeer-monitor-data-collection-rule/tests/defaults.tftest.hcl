mock_provider "azurerm" {}

variables {
  name                = "dcr-platform"
  resource_group_name = "rg-mon"
  location            = "eastus2"
  destinations = {
    log_analytics = {
      law = {
        name                  = "law-dest"
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/law"
      }
    }
  }
  data_flows = {
    perf = {
      streams      = ["Microsoft-Perf"]
      destinations = ["law-dest"]
    }
  }
}

run "create" {
  command = apply
  assert {
    condition     = azurerm_monitor_data_collection_rule.this.name == "dcr-platform"
    error_message = "name not wired"
  }
}
