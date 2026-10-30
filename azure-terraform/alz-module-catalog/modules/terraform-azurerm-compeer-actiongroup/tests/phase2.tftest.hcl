mock_provider "azurerm" {}
variables {
  name                = "platform-cus-prod-ag"
  resource_group_name = "monitor-rg"
  short_name          = "platops"
}
run "secure_itsm_webhook" {
  command = plan
  variables {
    receivers = { webhook = { itsm = {
      service_uri = "https://itsm.example.invalid/api/azure-alerts"
      aad_auth = {
        object_id      = "22222222-2222-2222-2222-222222222222"
        identifier_uri = "api://azure-monitor-itsm"
        tenant_id      = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
      }
    } } }
  }
  assert {
    condition     = length(azurerm_monitor_action_group.action_group.webhook_receiver[0].aad_auth) == 1
    error_message = "Secure webhook must carry Entra authentication without embedding credentials."
  }
}
