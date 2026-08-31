output "id" {
  description = "Resource ID of the service principal."
  value       = azuread_service_principal.service_principal.id
}

output "object_id" {
  description = "Object ID of the service principal (use for role assignments)."
  value       = azuread_service_principal.service_principal.object_id
}

output "client_id" {
  description = "Client ID of the underlying application."
  value       = azuread_service_principal.service_principal.client_id
}
