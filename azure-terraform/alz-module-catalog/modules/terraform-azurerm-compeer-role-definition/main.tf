resource "azurerm_role_definition" "this" {
  name               = var.name
  scope              = var.scope
  description        = var.description
  role_definition_id = var.role_definition_id
  assignable_scopes  = var.assignable_scopes

  dynamic "permissions" {
    for_each = var.permissions
    content {
      actions          = try(permissions.value.actions, [])
      not_actions      = try(permissions.value.not_actions, [])
      data_actions     = try(permissions.value.data_actions, [])
      not_data_actions = try(permissions.value.not_data_actions, [])
    }
  }
}
