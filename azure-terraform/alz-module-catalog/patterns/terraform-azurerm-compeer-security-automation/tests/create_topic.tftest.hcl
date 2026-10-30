mock_provider "azurerm" {}
run "create_topic_only_when_no_vault_owner_exists" {
  command = plan
  variables {
    secret_rotations = { service = {
      name                            = "service-secret-rotation"
      system_topic_name               = "new-vault-events"
      system_topic_resource_group     = "security-rg"
      create_system_topic             = true
      vault_id                        = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/security-rg/providers/Microsoft.KeyVault/vaults/new-kv"
      secret_names                    = ["service-password"]
      function_id                     = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/security-rg/providers/Microsoft.Web/sites/rotation-app/functions/RotateSecret"
      function_principal_id           = "22222222-2222-2222-2222-222222222222"
      dead_letter_storage_id          = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/security-rg/providers/Microsoft.Storage/storageAccounts/deadletter"
      dead_letter_container_name      = "failed-events"
      handler_acceptance_reference    = "EXAMPLE-ROTATION-TEST"
      handler_updates_backing_service = true
      event_delivery_network_ready    = true
    } }
  }
  assert {
    condition     = length(azurerm_eventgrid_system_topic.vault) == 1 && length(data.azurerm_eventgrid_system_topic.vault) == 0
    error_message = "Explicit topic creation must have one owner and not try to read a nonexistent topic."
  }
}
