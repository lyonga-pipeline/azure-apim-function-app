output "id" {
  description = "Resource ID of the Recovery Services vault."
  value       = azurerm_recovery_services_vault.this.id
}
output "name" {
  description = "Name of the Recovery Services vault."
  value       = azurerm_recovery_services_vault.this.name
}
output "resource_group_name" {
  description = "Name of the resource group containing the vault."
  value       = azurerm_recovery_services_vault.this.resource_group_name
}
output "location" {
  description = "Azure region of the vault."
  value       = azurerm_recovery_services_vault.this.location
}
output "identity_principal_id" {
  description = "Principal ID of the vault's system-assigned managed identity (null if none), for RBAC grants."
  value       = try(azurerm_recovery_services_vault.this.identity[0].principal_id, null)
}
output "identity_tenant_id" {
  description = "Tenant ID of the vault's system-assigned managed identity (null if none)."
  value       = try(azurerm_recovery_services_vault.this.identity[0].tenant_id, null)
}
output "backup_policy_vm_ids" {
  description = "VM backup policy IDs keyed by tier name."
  value       = { for k, v in azurerm_backup_policy_vm.this : k => v.id }
}
output "backup_policy_file_share_ids" {
  description = "File share backup policy IDs keyed by tier name."
  value       = { for k, v in azurerm_backup_policy_file_share.this : k => v.id }
}
