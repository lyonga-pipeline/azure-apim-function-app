mock_provider "azurerm" {
  mock_resource "azurerm_eventgrid_system_topic" {
    defaults = { identity = [{ type = "SystemAssigned", principal_id = "00000000-0000-0000-0000-000000000002", tenant_id = "00000000-0000-0000-0000-000000000003" }] }
  }
}
variables {
  vault_id                   = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/workload-rg/providers/Microsoft.KeyVault/vaults/pilot-vault"
  resource_group_name        = "workload-rg"
  location                   = "centralus"
  topic_name                 = "pilot-lifecycle"
  secret_names               = ["storage-key"]
  queue_id                   = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rotation-rg/providers/Microsoft.ServiceBus/namespaces/rotation/queues/vault-events"
  dead_letter_storage_id     = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rotation-rg/providers/Microsoft.Storage/storageAccounts/rotationstate"
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/management-rg/providers/Microsoft.OperationalInsights/workspaces/logs"
}
run "scheduled_only_has_no_event_delivery" {
  command = plan
  assert {
    condition     = length(azurerm_eventgrid_system_topic.vault) == 0 && length(azurerm_role_assignment.sender) == 0
    error_message = "Scheduler-only enrollment must not provision an event exception."
  }
}
run "events_require_approval" {
  command = plan
  variables { events_enabled = true }
  expect_failures = [terraform_data.contract]
}
run "approved_events_use_bus_not_function_push" {
  command = plan
  variables {
    events_enabled              = true
    delivery_exception_approved = true
  }
  assert {
    condition     = azurerm_eventgrid_system_topic_event_subscription.vault[0].service_bus_queue_endpoint_id == var.queue_id && toset(azurerm_eventgrid_system_topic_event_subscription.vault[0].included_event_types) == toset(["Microsoft.KeyVault.SecretNearExpiry"])
    error_message = "Use MI Service Bus delivery and only the intended expiry event."
  }
}
