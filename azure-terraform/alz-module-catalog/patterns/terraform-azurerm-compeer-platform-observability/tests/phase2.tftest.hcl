mock_provider "azurerm" {}
variables {
  resource_group_name        = "platform-cus-prod-monitor-rg"
  log_analytics_workspace_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.OperationalInsights/workspaces/central-law"
}
run "defaults_preserve_phase1" {
  command = plan
  assert {
    condition     = length(azurerm_monitor_scheduled_query_rules_alert_v2.platform) + length(azurerm_virtual_machine_extension.ama) + length(azurerm_application_insights_workbook.operations) + length(azurerm_network_connection_monitor.path) == 0
    error_message = "No new resources without explicit Phase 2 inputs."
  }
}
run "alert_routes_to_existing_action_group" {
  command = plan
  variables {
    action_group_ids = ["/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.Insights/actionGroups/central-ag"]
    log_alerts       = { connector = { name = "connector-missing", query = "Heartbeat | where TimeGenerated > ago(30m)", description = "Validate connector heartbeat." } }
  }
  assert {
    condition     = azurerm_monitor_scheduled_query_rules_alert_v2.platform["connector"].skip_query_validation == false
    error_message = "Do not disable real KQL validation."
  }
}
run "unroutable_alert_rejected" {
  command = plan
  variables {
    log_alerts = { connector = { name = "connector-missing", query = "Heartbeat", description = "Test." } }
  }
  expect_failures = [azurerm_monitor_scheduled_query_rules_alert_v2.platform]
}
run "ama_and_change_tracking_share_approved_dcr" {
  command = plan
  variables {
    agents = { dc01 = {
      virtual_machine_id         = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/identity-rg/providers/Microsoft.Compute/virtualMachines/dc01"
      os_type                    = "Windows"
      managed_identity_id        = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/ama-mi"
      identity_and_network_ready = true
      data_collection_rules      = { baseline = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.Insights/dataCollectionRules/windows-dcr" }
      change_tracking_enabled    = true
      change_tracking_dcr_ready  = true
      change_tracking_dcr_key    = "baseline"
    } }
  }
  assert {
    condition     = length(azurerm_virtual_machine_extension.ama) == 1 && length(azurerm_virtual_machine_extension.change_tracking) == 1 && length(azurerm_monitor_data_collection_rule_association.vm) == 1
    error_message = "AMA, inventory and stable-key DCR association must compose."
  }
}
run "private_ama_associates_configuration_endpoint" {
  command = plan
  variables {
    agents = { dc01 = {
      virtual_machine_id          = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/identity-rg/providers/Microsoft.Compute/virtualMachines/dc01"
      os_type                     = "Windows"
      managed_identity_id         = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/ama-mi"
      identity_and_network_ready  = true
      data_collection_rules       = { baseline = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.Insights/dataCollectionRules/windows-dcr" }
      private_ingestion_enabled   = true
      private_link_scope_ready    = true
      data_collection_endpoint_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.Insights/dataCollectionEndpoints/private-dce"
    } }
  }
  assert {
    condition     = azurerm_monitor_data_collection_rule_association.endpoint["dc01"].name == "configurationAccessEndpoint"
    error_message = "Private AMA needs the VM configuration DCE association as well as its DCR association."
  }
}
run "private_ama_reuses_external_configuration_association" {
  command = plan
  variables {
    agents = { dc01 = {
      virtual_machine_id                      = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/identity-rg/providers/Microsoft.Compute/virtualMachines/dc01"
      os_type                                 = "Windows"
      managed_identity_id                     = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/ama-mi"
      identity_and_network_ready              = true
      data_collection_rules                   = { baseline = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.Insights/dataCollectionRules/windows-dcr" }
      private_ingestion_enabled               = true
      private_link_scope_ready                = true
      data_collection_endpoint_id             = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.Insights/dataCollectionEndpoints/private-dce"
      manage_endpoint_association             = false
      external_endpoint_association_confirmed = true
    } }
  }
  assert {
    condition     = length(azurerm_monitor_data_collection_rule_association.endpoint) == 0
    error_message = "A configuration DCE association has only one owner."
  }
}
run "private_ama_without_endpoint_is_rejected" {
  command = plan
  variables {
    agents = { dc01 = {
      virtual_machine_id         = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/identity-rg/providers/Microsoft.Compute/virtualMachines/dc01"
      os_type                    = "Windows"
      managed_identity_id        = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/ama-mi"
      identity_and_network_ready = true
      data_collection_rules      = { baseline = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.Insights/dataCollectionRules/windows-dcr" }
      private_ingestion_enabled  = true
    } }
  }
  expect_failures = [var.agents]
}
run "native_export_failure_metric_routes_without_law_ingestion" {
  command = plan
  variables {
    action_group_ids = ["/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.Insights/actionGroups/central-ag"]
    metric_alerts = { export = {
      name             = "law-export-failed"
      scopes           = ["/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.OperationalInsights/workspaces/central-law"]
      metric_namespace = "Microsoft.OperationalInsights/workspaces"
      metric_name      = "ExportFailed"
      aggregation      = "Total"
      operator         = "GreaterThan"
      threshold        = 0
    } }
  }
  assert {
    condition     = length(module.metric_alerts) == 1
    error_message = "Native metric alerting must not depend on log ingestion being healthy."
  }
}
run "native_metric_without_recipient_is_rejected" {
  command = plan
  variables {
    metric_alerts = { export = {
      name             = "law-export-failed"
      scopes           = ["/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.OperationalInsights/workspaces/central-law"]
      metric_namespace = "Microsoft.OperationalInsights/workspaces"
      metric_name      = "ExportFailed"
      aggregation      = "Total"
      operator         = "GreaterThan"
      threshold        = 0
    } }
  }
  expect_failures = [terraform_data.metric_routing]
}
run "reuse_ama_has_no_second_extension" {
  command = plan
  variables {
    agents = { dc01 = {
      virtual_machine_id         = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/identity-rg/providers/Microsoft.Compute/virtualMachines/dc01"
      os_type                    = "Windows"
      managed_identity_id        = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/ama-mi"
      identity_and_network_ready = true
      install_agent              = false
      existing_agent_confirmed   = true
      data_collection_rules      = { baseline = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.Insights/dataCollectionRules/windows-dcr" }
    } }
  }
  assert {
    condition     = length(azurerm_virtual_machine_extension.ama) == 0 && length(azurerm_monitor_data_collection_rule_association.vm) == 1
    error_message = "Reuse must not adopt or duplicate another owner's extension."
  }
}
run "unready_agent_rejected" {
  command = plan
  variables {
    agents = { invalid = { virtual_machine_id = "invalid", os_type = "Windows", managed_identity_id = "invalid", identity_and_network_ready = false, data_collection_rules = {} } }
  }
  expect_failures = [var.agents]
}
run "workbook_and_connection_monitor_compose" {
  command = plan
  variables {
    workbooks = { health = { name = "22222222-2222-2222-2222-222222222222", display_name = "Platform health", data_json = "{\"version\":\"Notebook/1.0\",\"items\":[]}" } }
    connection_monitors = { dns = {
      name                      = "identity-dns"
      network_watcher_id        = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/NetworkWatcherRG/providers/Microsoft.Network/networkWatchers/NetworkWatcher_centralus"
      source_virtual_machine_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.Compute/virtualMachines/probe"
      destination_address       = "10.0.0.4"
      destination_port          = 53
      source_agent_ready        = true
    } }
  }
  assert {
    condition     = length(azurerm_application_insights_workbook.operations) == 1 && length(azurerm_network_connection_monitor.path) == 1
    error_message = "Workbooks and synthetic network paths need independently owned resources."
  }
}
