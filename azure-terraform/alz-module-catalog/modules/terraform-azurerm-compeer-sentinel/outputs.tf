output "onboarding_id" {
  description = "Sentinel onboarding resource ID when enabled."
  value       = try(azurerm_sentinel_log_analytics_workspace_onboarding.this[0].id, null)
}

output "data_connector_contract" {
  description = "Approved Sentinel connector target state."
  value       = terraform_data.data_connector_contract.output
}
