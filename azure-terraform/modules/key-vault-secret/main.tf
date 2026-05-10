resource "azurerm_key_vault_secret" "this" {
  for_each        = var.secrets
  name            = each.key
  value           = each.value.value
  key_vault_id    = var.key_vault_id
  content_type    = try(each.value.content_type, null)
  not_before_date = try(each.value.not_before_date, null)
  expiration_date = try(each.value.expiration_date, null)
  tags            = merge(var.tags, try(each.value.tags, {}))
}
