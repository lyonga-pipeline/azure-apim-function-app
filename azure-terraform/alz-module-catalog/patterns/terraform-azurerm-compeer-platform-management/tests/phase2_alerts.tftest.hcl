mock_provider "azurerm" {}
variables {
  subscription_id = "11111111-1111-1111-1111-111111111111"
  location        = "centralus"
  environment     = "prod"
  resource_group  = { name = "monitor-rg" }
  log_analytics   = { name = "platform-law" }
  action_group = {
    short_name = "platform"
    receivers = { webhook = { itsm = {
      service_uri = "https://itsm.example.invalid/api/azure"
      aad_auth    = { object_id = "22222222-2222-2222-2222-222222222222", tenant_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", identifier_uri = "api://itsm" }
    } } }
  }
}
run "baseline_alerts_remain_disabled_by_default" {
  command = plan
  assert {
    condition     = length(module.platform_metric_alerts) == 0
    error_message = "New root forwarding must not enable alerts by default."
  }
}
run "keyed_metric_criteria_and_service_health_are_routed" {
  command = plan
  variables {
    platform_alerts = {
      enabled = true
      metric_alerts = { availability = {
        name     = "gateway-health"
        scopes   = ["/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworkGateways/gateway"]
        criteria = { availability = { metric_namespace = "Microsoft.Network/virtualNetworkGateways", metric_name = "ExpressRouteGatewayCountOfRoutesAdvertisedToPeer", aggregation = "Average", operator = "LessThan", threshold = 1 } }
      } }
    }
  }
  assert {
    condition     = length(module.platform_metric_alerts) == 1 && length(azurerm_monitor_activity_log_alert.service_health) == 1
    error_message = "Approved metric maps and Service Health must compose through actual base modules."
  }
}
run "legacy_list_criteria_still_compose" {
  command = plan
  variables {
    platform_alerts = {
      enabled                = true
      service_health_enabled = false
      metric_alerts = { ingest = {
        name     = "workspace-ingest"
        scopes   = ["/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.OperationalInsights/workspaces/platform-law"]
        criteria = [{ metric_namespace = "Microsoft.OperationalInsights/workspaces", metric_name = "IngestionVolume", aggregation = "Total", operator = "GreaterThan", threshold = 1000 }]
      } }
    }
  }
  assert {
    condition     = length(module.platform_metric_alerts) == 1
    error_message = "List-shaped legacy static criteria must normalize without renaming the alert."
  }
}
