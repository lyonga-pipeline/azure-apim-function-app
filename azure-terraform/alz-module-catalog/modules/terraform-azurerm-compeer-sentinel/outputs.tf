output "onboarding_id" {
  description = "Sentinel onboarding resource ID when enabled."
  value       = try(azurerm_sentinel_log_analytics_workspace_onboarding.this[0].id, null)
}

output "enabled" {
  description = "Whether Sentinel onboarding is enabled."
  value       = var.enabled
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID supplied for Sentinel onboarding."
  value       = var.log_analytics_workspace_id
}

output "data_connector_contract" {
  description = "Approved Sentinel connector target state."
  value       = terraform_data.data_connector_contract.output
}

output "scheduled_alert_rule_ids" {
  description = "Scheduled analytics rule IDs keyed by rule name."
  value       = { for k, v in azurerm_sentinel_alert_rule_scheduled.this : k => v.id }
}
