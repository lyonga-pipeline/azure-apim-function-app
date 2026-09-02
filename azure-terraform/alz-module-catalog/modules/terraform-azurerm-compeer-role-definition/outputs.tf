output "id" {
  description = "Terraform resource ID of the role definition (composite of role_definition_resource_id and scope)."
  value       = azurerm_role_definition.this.id
}
output "name" {
  description = "Display name of the custom role definition."
  value       = azurerm_role_definition.this.name
}
output "role_definition_id" {
  description = "GUID of the role definition, used when creating role assignments."
  value       = azurerm_role_definition.this.role_definition_id
}
output "role_definition_resource_id" {
  description = "Fully qualified resource ID of the role definition."
  value       = azurerm_role_definition.this.role_definition_resource_id
}
output "scope" {
  description = "Scope at which the role definition was created."
  value       = azurerm_role_definition.this.scope
}
output "assignable_scopes" {
  description = "Scopes at which this role can be assigned."
  value       = azurerm_role_definition.this.assignable_scopes
}
