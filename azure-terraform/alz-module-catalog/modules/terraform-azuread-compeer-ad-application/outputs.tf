output "app_role_ids" {
  description = "A mapping of app role values to app role IDs, intended to be useful when referencing app roles in other resources in your configuration."
  value       = azuread_application.ad_application.app_role_ids
}

output "client_id" {
  description = "The application's client ID (formerly called application ID)."
  value       = azuread_application.ad_application.client_id
}

output "object_id" {
  description = "The application's object ID."
  value       = azuread_application.ad_application.object_id
}

output "oauth2_permission_scope_ids" {
  description = "A mapping of OAuth2.0 permission scope values to scope IDs, intended to be useful when referencing permission scopes in other resources in your configuration."
  value       = azuread_application.ad_application.oauth2_permission_scope_ids
}

output "publisher_domain" {
  description = "The verified publisher domain for the application."
  value       = azuread_application.ad_application.publisher_domain
}

output "id" {
  description = "The application's resource ID."
  value       = azuread_application.ad_application.id
}