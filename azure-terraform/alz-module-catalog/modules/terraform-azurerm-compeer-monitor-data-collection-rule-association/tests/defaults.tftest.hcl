mock_provider "azurerm" {}

variables {
  name                    = "dcra-vm01"
  target_resource_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Compute/virtualMachines/vm01"
  data_collection_rule_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mon/providers/Microsoft.Insights/dataCollectionRules/dcr-platform"
}

run "create" {
  command = apply
  assert {
    condition     = azurerm_monitor_data_collection_rule_association.association.target_resource_id == var.target_resource_id
    error_message = "target not wired"
  }
}

run "rejects_no_dcr_or_dce" {
  command = plan
  variables {
    data_collection_rule_id = null
  }
  expect_failures = [azurerm_monitor_data_collection_rule_association.association]
}

run "accepts_endpoint_only_association" {
  # The success path using ONLY data_collection_endpoint_id (no DCR) had
  # never been tested - only the DCR-only success path and the neither-set
  # failure existed before this.
  command = apply
  variables {
    data_collection_rule_id     = null
    data_collection_endpoint_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mon/providers/Microsoft.Insights/dataCollectionEndpoints/dce-platform"
  }

  assert {
    condition     = azurerm_monitor_data_collection_rule_association.association.data_collection_endpoint_id != null
    error_message = "data_collection_endpoint_id alone should be accepted"
  }
  assert {
    condition     = output.id == azurerm_monitor_data_collection_rule_association.association.id && output.name == azurerm_monitor_data_collection_rule_association.association.name
    error_message = "id/name outputs must echo the resource"
  }
}
