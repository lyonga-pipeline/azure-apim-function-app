output "workspace_id" {
  description = "Log Analytics workspace ID the content is attached to."
  value       = local.workspace_id
}

output "onboarding_id" {
  description = "Sentinel onboarding resource ID when this state manages onboarding, otherwise null."
  value       = try(azurerm_sentinel_log_analytics_workspace_onboarding.onboarding[0].id, null)
}

output "connector_ids" {
  description = "Terraform-owned data connector IDs keyed by logical connector (Defender for Cloud and TAXII connectors are keyed by their map key)."
  value = merge(
    { for name, resource in {
      entra_id                      = try(azurerm_sentinel_data_connector_azure_active_directory.entra_id[0].id, null)
      defender_xdr                  = try(azurerm_sentinel_data_connector_microsoft_threat_protection.defender_xdr[0].id, null)
      defender_for_endpoint         = try(azurerm_sentinel_data_connector_microsoft_defender_advanced_threat_protection.defender_for_endpoint[0].id, null)
      defender_for_identity         = try(azurerm_sentinel_data_connector_azure_advanced_threat_protection.defender_for_identity[0].id, null)
      defender_for_cloud_apps       = try(azurerm_sentinel_data_connector_microsoft_cloud_app_security.defender_for_cloud_apps[0].id, null)
      office_atp                    = try(azurerm_sentinel_data_connector_office_atp.office_atp[0].id, null)
      office_irm                    = try(azurerm_sentinel_data_connector_office_irm.office_irm[0].id, null)
      power_bi                      = try(azurerm_sentinel_data_connector_office_power_bi.power_bi[0].id, null)
      office_365                    = try(azurerm_sentinel_data_connector_office_365.office_365[0].id, null)
      threat_intelligence           = try(azurerm_sentinel_data_connector_threat_intelligence.threat_intelligence[0].id, null)
      microsoft_threat_intelligence = try(azurerm_sentinel_data_connector_microsoft_threat_intelligence.microsoft_threat_intelligence[0].id, null)
    } : name => resource if resource != null },
    { for key, resource in azurerm_sentinel_data_connector_azure_security_center.defender_for_cloud : "defender_for_cloud/${key}" => resource.id },
    { for key, resource in azurerm_sentinel_data_connector_threat_intelligence_taxii.taxii : "taxii/${key}" => resource.id },
  )
}

output "analytics_rule_ids" {
  description = "IDs of every analytics rule created here, keyed by rule key."
  value = merge(
    local.analytic_rule_ids,
    { for key, resource in azurerm_sentinel_alert_rule_fusion.fusion : key => resource.id },
    { for key, resource in azurerm_sentinel_alert_rule_threat_intelligence.threat_intelligence : key => resource.id },
    { for key, resource in azurerm_sentinel_alert_rule_machine_learning_behavior_analytics.ml_behavior_analytics : key => resource.id },
    { for key, resource in azurerm_sentinel_alert_rule_anomaly_built_in.anomaly : key => resource.id },
  )
}

output "automation_rule_ids" {
  description = "Automation rule IDs keyed by rule key."
  value       = { for key, resource in azurerm_sentinel_automation_rule.automation : key => resource.id }
}

output "watchlist_ids" {
  description = "Watchlist IDs keyed by watchlist alias."
  value       = { for key, resource in azurerm_sentinel_watchlist.watchlist : key => resource.id }
}

output "content_inventory" {
  description = "What this state owns, by kind - an audit view for the SOC and platform team."
  value = {
    scheduled_rules          = sort(keys(local.scheduled_rules))
    nrt_rules                = sort(keys(var.nrt_rules))
    microsoft_incident_rules = sort(keys(var.microsoft_incident_rules))
    template_rules           = sort(keys(var.template_rules))
    anomaly_rules            = sort(keys(var.anomaly_rules))
    automation_rules         = sort(keys(var.automation_rules))
    watchlists               = sort(keys(var.watchlists))
    baseline_enabled         = var.baseline_content.enabled
    ingestion = {
      endpoints     = sort(keys(local.ingestion_endpoints))
      custom_tables = sort(keys(local.ingestion_tables))
      rules         = sort(keys(local.ingestion_rules))
      associations  = sort(keys(local.ingestion_associations))
    }
  }
}

output "source_coverage" {
  description = "Telemetry sources available to rules (provided by connectors here or declared external) and any enabled rule requirements that are not covered."
  value = {
    available = sort(tolist(local.available_sources))
    unmet     = local.unmet_sources
  }
}

output "data_collection_endpoint_ids" {
  description = "Data collection endpoint IDs keyed by ingestion.endpoints key."
  value       = { for key, resource in azurerm_monitor_data_collection_endpoint.endpoint : key => resource.id }
}

output "data_collection_rule_ids" {
  description = "Data collection rule IDs keyed by ingestion.rules key."
  value       = { for key, resource in azurerm_monitor_data_collection_rule.rule : key => resource.id }
}

output "custom_table_ids" {
  description = "Custom table IDs keyed by table name."
  value       = { for key, resource in azurerm_log_analytics_workspace_table_custom_log.table : key => resource.id }
}

output "ingestion_targets" {
  description = "Connection details to hand to a third-party pipeline (Cribl and similar) for each custom_ingestion rule: the data collection endpoint URL, the rule's immutable ID and the stream name to send to. The pipeline's Entra application needs its object ID listed in that rule's publisher_principal_ids."
  value = {
    for key, rule in local.custom_ingestion_rules : key => {
      table                   = rule.table_key
      stream_name             = local.custom_input_streams[key]
      dcr_id                  = azurerm_monitor_data_collection_rule.rule[key].id
      dcr_immutable_id        = azurerm_monitor_data_collection_rule.rule[key].immutable_id
      logs_ingestion_url      = azurerm_monitor_data_collection_endpoint.endpoint[rule.endpoint_key].logs_ingestion_endpoint
      publisher_principal_ids = sort(tolist(rule.publisher_principal_ids))
    }
  }
}
