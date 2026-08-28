locals {
  tags = merge({
    ManagedBy = "Terraform"
    IaCSource = "CompeerHCP"
    Phase     = "2"
  }, var.tags)

  default_operational_contracts = {
    sentinel_content = {
      phase                = "Phase 2"
      implementation_state = "contract-only"
      required_controls    = ["analytics rules", "workbooks", "automation playbooks", "SOC approval"]
      notes                = "SEC-04 Sentinel content should be versioned after the SOC confirms rule tuning and ownership."
    }
    azure_monitor_agent_dcr = {
      phase                = "Phase 2"
      implementation_state = "contract-only"
      required_controls    = ["DCR scope model", "AMA rollout plan", "agent policy assignments", "data volume budget"]
      notes                = "OBS-06 is best implemented once workload VM inventory and log tables are confirmed."
    }
    workbooks_dashboards = {
      phase                = "Phase 2"
      implementation_state = "contract-only"
      required_controls    = ["executive workbook", "platform operations workbook", "security workbook"]
      notes                = "OBS-07 artifacts should be promoted through source-controlled templates after pilot telemetry stabilizes."
    }
    itsm_ticketing = {
      phase                = "Phase 2"
      implementation_state = "contract-only"
      required_controls    = ["action group receiver", "routing rules", "ticket severity mapping"]
      notes                = "OBS-08 depends on the enterprise ITSM endpoint and authentication model."
    }
    update_manager_change_tracking_arc = {
      phase                = "Phase 2"
      implementation_state = "contract-only"
      required_controls    = ["Update Manager schedules", "Change Tracking", "Azure Arc onboarding for hybrid servers"]
      notes                = "PLT-04, PLT-05, and PLT-08 require server inventory and maintenance windows."
    }
    jit_and_secret_rotation = {
      phase                = "Phase 2"
      implementation_state = "contract-only"
      required_controls    = ["JIT policy", "secret rotation workflow", "break-glass review"]
      notes                = "SEC-11 and SEC-13 should be implemented after PIM and Key Vault ownership are finalized."
    }
    dr_runbooks = {
      phase                = "Phase 2"
      implementation_state = "manual-runbook"
      required_controls    = ["RTO/RPO targets", "test cadence", "failover and failback evidence"]
      notes                = "DR-05 is a documented and tested operating model, not a standalone Azure resource."
    }
  }
}

module "action_group" {
  for_each = var.action_groups
  source   = "app.terraform.io/Compeer-Financial-Services/compeer-action-group/azurerm"
  version  = "1.0.0"

  name                = each.value.name
  resource_group_name = var.resource_group_name
  short_name          = each.value.short_name
  enabled             = try(each.value.enabled, true)
  receivers           = try(each.value.receivers, {})
  tags                = local.tags
}

module "metric_alert" {
  for_each = var.metric_alerts
  source   = "app.terraform.io/Compeer-Financial-Services/compeer-monitor-metric-alert/azurerm"
  version  = "1.0.0"

  name                                                         = each.value.name
  resource_group_name                                          = var.resource_group_name
  scopes                                                       = each.value.scopes
  description                                                  = try(each.value.description, null)
  enabled                                                      = try(each.value.enabled, true)
  auto_mitigate                                                = try(each.value.auto_mitigate, true)
  severity                                                     = try(each.value.severity, 3)
  frequency                                                    = try(each.value.frequency, "PT5M")
  window_size                                                  = try(each.value.window_size, "PT5M")
  target_resource_type                                         = try(each.value.target_resource_type, null)
  target_resource_location                                     = try(each.value.target_resource_location, null)
  criteria                                                     = try(each.value.criteria, {})
  dynamic_criteria                                             = try(each.value.dynamic_criteria, null)
  application_insights_web_test_location_availability_criteria = try(each.value.application_insights_web_test_location_availability_criteria, null)
  actions = merge(
    {
      for action_group_key in try(each.value.action_group_keys, []) : action_group_key => {
        action_group_id = module.action_group[action_group_key].id
      }
    },
    try(each.value.actions, {})
  )
  tags = local.tags
}

module "operational_contracts" {
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-operational-contracts/azurerm"
  version = "1.0.0"

  contracts = merge(local.default_operational_contracts, var.operational_contracts)
}
