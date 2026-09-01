# =============================================================================
# Sentinel content: data connectors + scheduled analytics rules.
#
# deploy-runbook.tf §5.7 (NOT optional): Palo Alto -> Panorama/syslog/CEF ->
# Log Analytics / Sentinel, with an alert on a broken forwarding path.
#
# The CEF/Syslog transport is a Data Collection Rule on the forwarder VM
# (owned by the connectivity / management pattern); this module owns the
# Sentinel-side connector state and the analytics rules.
# =============================================================================

# Threat-intelligence / CEF-style connectors that Terraform can own directly.
resource "azurerm_sentinel_data_connector_threat_intelligence" "this" {
  count                      = var.enabled && try(var.data_connectors.threat_intelligence, false) ? 1 : 0
  name                       = "ti"
  log_analytics_workspace_id = azurerm_sentinel_log_analytics_workspace_onboarding.this[0].workspace_id
}

resource "azurerm_sentinel_data_connector_microsoft_defender_advanced_threat_protection" "this" {
  count                      = var.enabled && try(var.data_connectors.defender_atp, false) ? 1 : 0
  name                       = "mdatp"
  log_analytics_workspace_id = azurerm_sentinel_log_analytics_workspace_onboarding.this[0].workspace_id
}

resource "azurerm_sentinel_data_connector_azure_active_directory" "this" {
  count                      = var.enabled && try(var.data_connectors.entra_id, false) ? 1 : 0
  name                       = "aad"
  log_analytics_workspace_id = azurerm_sentinel_log_analytics_workspace_onboarding.this[0].workspace_id
}

resource "azurerm_sentinel_data_connector_azure_security_center" "this" {
  count                      = var.enabled && try(var.data_connectors.defender_for_cloud, false) ? 1 : 0
  name                       = "mdc"
  log_analytics_workspace_id = azurerm_sentinel_log_analytics_workspace_onboarding.this[0].workspace_id
}

# Baseline scheduled analytics rules, incl. the mandatory Palo-Alto /
# CommonSecurityLog forwarding-health rule.
locals {
  default_rules = {
    palo-alto-forwarding-stopped = {
      display_name        = "Palo Alto - CEF forwarding stopped"
      severity            = "High"
      query               = <<-KQL
        CommonSecurityLog
        | where DeviceVendor == "Palo Alto Networks"
        | summarize LastEvent = max(TimeGenerated)
        | where LastEvent < ago(30m)
      KQL
      query_frequency     = "PT15M"
      query_period        = "PT1H"
      trigger_operator    = "GreaterThan"
      trigger_threshold   = 0
      tactics             = ["Impact"]
      suppression_enabled = false
    }
    palo-alto-threat-critical = {
      display_name      = "Palo Alto - critical threat log"
      severity          = "High"
      query             = <<-KQL
        CommonSecurityLog
        | where DeviceVendor == "Palo Alto Networks" and DeviceProduct == "PAN-OS"
        | where Activity == "THREAT" and LogSeverity in ("critical", "high")
      KQL
      query_frequency   = "PT15M"
      query_period      = "PT15M"
      trigger_operator  = "GreaterThan"
      trigger_threshold = 0
      tactics           = ["CommandAndControl", "Exfiltration"]
    }
  }
  scheduled_rules = merge(
    { for k, v in local.default_rules : k => v if var.include_default_rules },
    var.scheduled_alert_rules,
  )
}

resource "azurerm_sentinel_alert_rule_scheduled" "this" {
  for_each = var.enabled ? local.scheduled_rules : {}

  name                       = each.key
  log_analytics_workspace_id = azurerm_sentinel_log_analytics_workspace_onboarding.this[0].workspace_id
  display_name               = each.value.display_name
  severity                   = each.value.severity
  query                      = each.value.query
  query_frequency            = try(each.value.query_frequency, "PT1H")
  query_period               = try(each.value.query_period, "PT1H")
  trigger_operator           = try(each.value.trigger_operator, "GreaterThan")
  trigger_threshold          = try(each.value.trigger_threshold, 0)
  tactics                    = try(each.value.tactics, null)
  enabled                    = try(each.value.enabled, true)

  dynamic "incident" {
    for_each = try(each.value.create_incident, true) ? [1] : []
    content {
      create_incident_enabled = true
      grouping {
        enabled = try(each.value.grouping_enabled, true)
      }
    }
  }
}
