mock_provider "azurerm" {
  mock_data "azurerm_eventgrid_system_topic" {
    defaults = {
      source_resource_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/security-rg/providers/Microsoft.KeyVault/vaults/platform-kv"
      topic_type         = "Microsoft.KeyVault.vaults"
      identity = [{
        type      = "SystemAssigned", principal_id = "33333333-3333-3333-3333-333333333333",
        tenant_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", identity_ids = []
      }]
    }
  }
}
run "no_rotation_without_handler" {
  command = plan
  assert {
    condition     = length(azurerm_eventgrid_system_topic_event_subscription.rotation) == 0
    error_message = "No false claim of automatic secret rotation."
  }
}
run "approved_rotation_wires_events_and_dead_letters" {
  command = plan
  variables {
    secret_rotations = { platform = {
      name                            = "platform-secret-rotation"
      system_topic_name               = "platform-kv-events"
      system_topic_resource_group     = "security-rg"
      vault_id                        = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/security-rg/providers/Microsoft.KeyVault/vaults/platform-kv"
      secret_names                    = ["service-password"]
      function_id                     = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/security-rg/providers/Microsoft.Web/sites/rotation-app/functions/RotateSecret"
      function_principal_id           = "22222222-2222-2222-2222-222222222222"
      dead_letter_storage_id          = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/security-rg/providers/Microsoft.Storage/storageAccounts/deadletter"
      dead_letter_container_name      = "failed-events"
      topic_principal_id              = "33333333-3333-3333-3333-333333333333"
      handler_acceptance_reference    = "EXAMPLE-ROTATION-TEST"
      handler_updates_backing_service = true
      event_delivery_network_ready    = true
    } }
  }
  assert {
    condition     = azurerm_eventgrid_system_topic_event_subscription.rotation["platform"].included_event_types == tolist(["Microsoft.KeyVault.SecretNearExpiry"]) && length(azurerm_role_assignment.rotation_writer) == 1
    error_message = "Rotate only approved secrets; keep dead-letter and least-privilege RBAC wiring."
  }
}
run "untested_handler_rejected" {
  command = plan
  variables {
    secret_rotations = { invalid = {
      name = "invalid", system_topic_name = "invalid", system_topic_resource_group = "security-rg", vault_id = "invalid", secret_names = [], function_id = "invalid", function_principal_id = "22222222-2222-2222-2222-222222222222", dead_letter_storage_id = "invalid", dead_letter_container_name = "failed-events", topic_principal_id = "33333333-3333-3333-3333-333333333333", handler_acceptance_reference = "", handler_updates_backing_service = false, event_delivery_network_ready = false
    } }
  }
  expect_failures = [var.secret_rotations]
}
