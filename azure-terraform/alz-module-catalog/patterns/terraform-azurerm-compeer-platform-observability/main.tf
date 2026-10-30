# PHASE2 NEW: additive, independently owned extensions; all collections default empty.
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "platform" {
  for_each              = var.log_alerts
  name                  = each.value.name
  resource_group_name   = var.resource_group_name
  location              = var.location
  scopes                = [var.log_analytics_workspace_id]
  description           = each.value.description
  enabled               = each.value.enabled
  severity              = each.value.severity
  evaluation_frequency  = each.value.evaluation_frequency
  window_duration       = each.value.window_duration
  skip_query_validation = false
  criteria {
    query                   = each.value.query
    time_aggregation_method = each.value.aggregation
    metric_measure_column   = each.value.metric_measure_column
    operator                = each.value.operator
    threshold               = each.value.threshold
    dynamic "dimension" {
      for_each = each.value.dimensions
      content {
        name     = dimension.value.name
        operator = dimension.value.operator
        values   = dimension.value.values
      }
    }
    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }
  action { action_groups = tolist(var.action_group_ids) }
  tags = var.tags
  lifecycle {
    precondition {
      condition     = !each.value.enabled || length(var.action_group_ids) > 0
      error_message = "Enabled platform alerts require an approved, tested action-group route."
    }
  }
}

resource "azurerm_virtual_machine_extension" "ama" {
  for_each                   = { for key, agent in var.agents : key => agent if agent.install_agent }
  name                       = each.value.os_type == "Windows" ? "AzureMonitorWindowsAgent" : "AzureMonitorLinuxAgent"
  virtual_machine_id         = each.value.virtual_machine_id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = each.value.os_type == "Windows" ? "AzureMonitorWindowsAgent" : "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true
  settings = jsonencode({ authentication = { managedIdentity = {
    "identifier-name" = "mi_res_id", "identifier-value" = each.value.managed_identity_id
  } } })
  tags = var.tags
}

resource "azurerm_monitor_data_collection_rule_association" "vm" {
  for_each                = local.associations
  name                    = "phase2-${substr(sha256(each.key), 0, 16)}"
  target_resource_id      = each.value.vm_id
  data_collection_rule_id = each.value.dcr_id
  depends_on              = [azurerm_virtual_machine_extension.ama]
}

# One DCE configuration endpoint per VM. Import an existing association, or leave it with its owner.
resource "azurerm_monitor_data_collection_rule_association" "endpoint" {
  for_each                    = { for key, agent in var.agents : key => agent if agent.data_collection_endpoint_id != null && agent.manage_endpoint_association }
  name                        = "configurationAccessEndpoint"
  target_resource_id          = each.value.virtual_machine_id
  data_collection_endpoint_id = each.value.data_collection_endpoint_id
}

resource "azurerm_virtual_machine_extension" "change_tracking" {
  for_each                   = { for key, agent in var.agents : key => agent if agent.change_tracking_enabled }
  name                       = each.value.os_type == "Windows" ? "ChangeTracking-Windows" : "ChangeTracking-Linux"
  virtual_machine_id         = each.value.virtual_machine_id
  publisher                  = "Microsoft.Azure.ChangeTrackingAndInventory"
  type                       = each.value.os_type == "Windows" ? "ChangeTracking-Windows" : "ChangeTracking-Linux"
  type_handler_version       = each.value.change_tracking_version
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true
  tags                       = var.tags
  depends_on                 = [azurerm_monitor_data_collection_rule_association.vm, azurerm_monitor_data_collection_rule_association.endpoint]
}

resource "azurerm_application_insights_workbook" "operations" {
  for_each            = var.workbooks
  name                = each.value.name
  display_name        = each.value.display_name
  resource_group_name = var.resource_group_name
  location            = var.location
  source_id           = lower(var.log_analytics_workspace_id)
  data_json           = each.value.data_json
  tags                = var.tags
}

resource "azurerm_network_connection_monitor" "path" {
  for_each                      = var.connection_monitors
  name                          = each.value.name
  location                      = var.location
  network_watcher_id            = each.value.network_watcher_id
  output_workspace_resource_ids = [var.log_analytics_workspace_id]
  endpoint {
    name               = "source"
    target_resource_id = each.value.source_virtual_machine_id
  }
  endpoint {
    name    = "destination"
    address = each.value.destination_address
  }
  test_configuration {
    name                      = "tcp"
    protocol                  = "Tcp"
    test_frequency_in_seconds = each.value.frequency_seconds
    tcp_configuration { port = each.value.destination_port }
    success_threshold {
      checks_failed_percent = each.value.maximum_failed_percent
      round_trip_time_ms    = each.value.maximum_round_trip_time_ms
    }
  }
  test_group {
    name                     = "critical-path"
    source_endpoints         = ["source"]
    destination_endpoints    = ["destination"]
    test_configuration_names = ["tcp"]
    enabled                  = true
  }
  tags = var.tags
}

resource "terraform_data" "metric_routing" {
  count = length(var.metric_alerts) > 0 ? 1 : 0
  lifecycle {
    precondition {
      condition     = length(var.action_group_ids) > 0
      error_message = "Native metric alerts require a tested existing action-group route."
    }
  }
}
module "metric_alerts" {
  for_each                 = var.metric_alerts
  source                   = "../../modules/terraform-azurerm-compeer-monitor-metric-alert"
  name                     = each.value.name
  resource_group_name      = var.resource_group_name
  scopes                   = each.value.scopes
  target_resource_type     = each.value.target_resource_type
  target_resource_location = each.value.target_resource_location
  severity                 = each.value.severity
  frequency                = each.value.frequency
  window_size              = each.value.window_size
  criteria = { platform = {
    metric_namespace       = each.value.metric_namespace
    metric_name            = each.value.metric_name
    aggregation            = each.value.aggregation
    operator               = each.value.operator
    threshold              = each.value.threshold
    dimensions             = each.value.dimensions
    skip_metric_validation = false
  } }
  actions    = { for index, id in sort(tolist(var.action_group_ids)) : "route-${index}" => { action_group_id = id } }
  tags       = var.tags
  depends_on = [terraform_data.metric_routing]
}
