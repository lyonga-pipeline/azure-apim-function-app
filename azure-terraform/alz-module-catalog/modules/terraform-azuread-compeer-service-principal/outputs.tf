output "object_id" {
  description = "The application's object ID."
  value       = azuread_service_principal.service_principal.object_id
}
