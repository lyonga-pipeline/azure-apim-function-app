output "id" {
  description = "Resource ID of the user-assigned identity."
  value       = azurerm_user_assigned_identity.identity.id
}

output "name" {
  description = "Name of the user-assigned identity."
  value       = azurerm_user_assigned_identity.identity.name
}

output "client_id" {
  description = "Client ID of the identity (for app auth)."
  value       = azurerm_user_assigned_identity.identity.client_id
}

output "principal_id" {
  description = "Principal (object) ID of the identity (for role assignments)."
  value       = azurerm_user_assigned_identity.identity.principal_id
}

output "tenant_id" {
  description = "Tenant ID of the identity."
  value       = azurerm_user_assigned_identity.identity.tenant_id
}
