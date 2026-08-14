locals {
  assignments = {
    for key, value in var.assignments :
    key => merge(value, {
      role_definition_name = try(value.role_definition_name, null)
      role_definition_id   = try(value.role_definition_id, null)
    })
  }
}

resource "azurerm_role_assignment" "this" {
  for_each = local.assignments

  scope                                  = each.value.scope
  principal_id                           = each.value.principal_id
  principal_type                         = try(each.value.principal_type, null)
  role_definition_id                     = each.value.role_definition_id
  role_definition_name                   = each.value.role_definition_id == null ? each.value.role_definition_name : null
  skip_service_principal_aad_check       = try(each.value.skip_service_principal_aad_check, null)
  condition                              = try(each.value.condition, null)
  condition_version                      = try(each.value.condition_version, null)
  delegated_managed_identity_resource_id = try(each.value.delegated_managed_identity_resource_id, null)
  description                            = try(each.value.description, null)
}
