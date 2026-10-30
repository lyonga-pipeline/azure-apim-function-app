mock_provider "azurerm" {
  mock_data "azurerm_eventgrid_system_topic" {
    defaults = {
      source_resource_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/security-rg/providers/Microsoft.KeyVault/vaults/platform-kv"
      topic_type         = "Microsoft.KeyVault.vaults"
      identity           = [{ type = "SystemAssigned", principal_id = "33333333-3333-3333-3333-333333333333", tenant_id = "44444444-4444-4444-4444-444444444444" }]
    }
  }
}
run "enabled_rotation_example_is_fully_wired" {
  command = plan
  assert {
    condition     = length(module.phase2.secret_rotation_subscription_ids) == 1
    error_message = "The approved rotation pilot must reuse the declared vault topic and wire event delivery."
  }
}
