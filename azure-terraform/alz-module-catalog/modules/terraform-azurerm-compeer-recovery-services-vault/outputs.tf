output "id" { value = azurerm_recovery_services_vault.this.id }
output "name" { value = azurerm_recovery_services_vault.this.name }
output "resource_group_name" { value = azurerm_recovery_services_vault.this.resource_group_name }
output "location" { value = azurerm_recovery_services_vault.this.location }
output "identity_principal_id" { value = try(azurerm_recovery_services_vault.this.identity[0].principal_id, null) }
output "identity_tenant_id" { value = try(azurerm_recovery_services_vault.this.identity[0].tenant_id, null) }
