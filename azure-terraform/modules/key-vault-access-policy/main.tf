resource "azurerm_key_vault_access_policy" "this" {
  for_each = var.policies

  key_vault_id = var.key_vault_id
  tenant_id    = each.value.tenant_id
  object_id    = each.value.object_id

  application_id          = try(each.value.application_id, null)
  certificate_permissions = try(each.value.certificate_permissions, null)
  key_permissions         = try(each.value.key_permissions, null)
  secret_permissions      = try(each.value.secret_permissions, null)
  storage_permissions     = try(each.value.storage_permissions, null)
}
