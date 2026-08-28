output "ids" {
  value = { for key, value in azurerm_role_assignment.this : key => value.id }
}

output "names" {
  value = { for key, value in azurerm_role_assignment.this : key => value.name }
}

output "assignments" {
  value = {
    for key, value in azurerm_role_assignment.this : key => {
      id                   = value.id
      name                 = value.name
      scope                = value.scope
      principal_id         = value.principal_id
      role_definition_id   = value.role_definition_id
      role_definition_name = value.role_definition_name
      principal_type       = value.principal_type
    }
  }
}
