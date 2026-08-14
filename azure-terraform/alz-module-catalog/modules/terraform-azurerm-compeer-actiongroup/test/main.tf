module "action_group" {
  source = "../"

  resource_group_name     = "openai2-ncus-sb4-rg"
  action_group_name       = "test-action-group"
  action_group_short_name = "testacgrp"

  actiongrp_automation_runbook_receiver = [{
    name                  = "test-automation-receiver"
    automation_account_id = "/subscriptions/7acfa79c-1fd6-4e91-8958-1da372ff631f/resourceGroups/openai2-ncus-sb4-rg/providers/Microsoft.Automation/automationAccounts/openai2-sb4-automation"
    runbook_name          = "OpenAI2-StopAppGtwy"
    webhook_resource_id   = "subscriptions/7acfa79c-1fd6-4e91-8958-1da372ff631f/resourceGroups/openai2-ncus-sb4-rg/providers/Microsoft.Automation/automationAccounts/openai2-sb4-automation/webHooks/test"
    service_uri           = "https://24cd70b9-511d-41ee-b4e3-c64fa2b439b6.webhook.eus2.azure-automation.net/webhooks?token=jLxPMO97a3D2P6minYHP8MrSE6jpTUhaEVbJXDceJQM%3d"
    is_global_runbook     = true
  }]
}