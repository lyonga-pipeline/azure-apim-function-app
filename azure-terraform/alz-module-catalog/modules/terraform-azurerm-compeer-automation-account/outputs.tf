output "id" {
  description = "Resource ID of the automation account."
  value       = azurerm_automation_account.this.id
}
output "name" {
  description = "Name of the automation account."
  value       = azurerm_automation_account.this.name
}
output "identity" {
  description = "Managed identity block of the automation account (type, principal_id, tenant_id)."
  value       = azurerm_automation_account.this.identity
}
output "dsc_server_endpoint" {
  description = "DSC pull server endpoint URL for the automation account."
  value       = azurerm_automation_account.this.dsc_server_endpoint
}
output "dsc_primary_access_key" {
  description = "Primary access key for the DSC pull server (sensitive)."
  value       = azurerm_automation_account.this.dsc_primary_access_key
  sensitive   = true
}
output "dsc_secondary_access_key" {
  description = "Secondary access key for the DSC pull server (sensitive)."
  value       = azurerm_automation_account.this.dsc_secondary_access_key
  sensitive   = true
}
