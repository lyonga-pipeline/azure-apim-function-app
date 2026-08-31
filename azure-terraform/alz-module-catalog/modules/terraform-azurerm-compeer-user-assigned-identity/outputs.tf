output "id" {
  description = "Resource ID of the user-assigned identity."
  value       = azurerm_user_assigned_identity.this.id
}

output "name" {
  description = "Name of the user-assigned identity."
  value       = azurerm_user_assigned_identity.this.name
}

output "client_id" {
  description = "Client ID of the identity (for app auth)."
  value       = azurerm_user_assigned_identity.this.client_id
}

output "principal_id" {
  description = "Principal (object) ID of the identity (for role assignments)."
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "tenant_id" {
  description = "Tenant ID of the identity."
  value       = azurerm_user_assigned_identity.this.tenant_id
}
