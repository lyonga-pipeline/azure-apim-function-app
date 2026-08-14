output "server_endpoint" {
  description = "Automation account server endpoint"
  value       = azurerm_automation_account.this.dsc_server_endpoint
}

output "dsc_primary_access_key" {
  description = "Primary Access Key for the DSC endpoint associated with Automation Account."
  value       = azurerm_automation_account.this.dsc_primary_access_key
  sensitive   = true
}

output "dsc_secondary_access_key" {
  description = "Secondary Access Key for the DSC endpoint associated with Automation Account."
  value       = azurerm_automation_account.this.dsc_secondary_access_key
  sensitive   = true
}

output "runbook_webhook_id" {
  description = "Webhook ID for the Automation"
  value       = azurerm_automation_webhook.this.*.id
}

output "runbook_webhook_uri" {
  description = "Generated URI for the webhook"
  value       = azurerm_automation_webhook.this.*.uri
}