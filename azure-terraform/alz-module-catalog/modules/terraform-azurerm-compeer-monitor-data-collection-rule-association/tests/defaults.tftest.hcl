mock_provider "azurerm" {}

variables {
  name                    = "dcra-vm01"
  target_resource_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Compute/virtualMachines/vm01"
  data_collection_rule_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mon/providers/Microsoft.Insights/dataCollectionRules/dcr-platform"
}

run "create" {
  command = apply
  assert {
    condition     = azurerm_monitor_data_collection_rule_association.this.target_resource_id == var.target_resource_id
    error_message = "target not wired"
  }
}

run "rejects_no_dcr_or_dce" {
  command = plan
  variables {
    data_collection_rule_id = null
  }
  expect_failures = [azurerm_monitor_data_collection_rule_association.this]
}
