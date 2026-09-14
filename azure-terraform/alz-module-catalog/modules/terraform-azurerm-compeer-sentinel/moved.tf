# Resource-address history for the "this" -> semantic-name cleanup.
# Keeps a plan against already-applied state a pure state move (no
# destroy/recreate) instead of replacing every renamed resource.
# Safe to delete once every real workspace has applied past this change.

moved {
  from = azurerm_sentinel_data_connector_threat_intelligence.this
  to   = azurerm_sentinel_data_connector_threat_intelligence.threat_intel_connector
}

moved {
  from = azurerm_sentinel_data_connector_microsoft_defender_advanced_threat_protection.this
  to   = azurerm_sentinel_data_connector_microsoft_defender_advanced_threat_protection.mdatp_connector
}

moved {
  from = azurerm_sentinel_data_connector_azure_active_directory.this
  to   = azurerm_sentinel_data_connector_azure_active_directory.aad_connector
}

moved {
  from = azurerm_sentinel_data_connector_azure_security_center.this
  to   = azurerm_sentinel_data_connector_azure_security_center.defender_connector
}

moved {
  from = azurerm_sentinel_alert_rule_scheduled.this
  to   = azurerm_sentinel_alert_rule_scheduled.scheduled_rule
}

moved {
  from = azurerm_sentinel_log_analytics_workspace_onboarding.this
  to   = azurerm_sentinel_log_analytics_workspace_onboarding.onboarding
}
