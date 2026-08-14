locals {
  secret_names = toset(nonsensitive(keys(var.secrets)))
}

resource "azurerm_key_vault_secret" "this" {
  for_each        = local.secret_names
  name            = each.key
  value           = var.secrets[each.key].value
  key_vault_id    = var.key_vault_id
  content_type    = try(var.secrets[each.key].content_type, null)
  not_before_date = try(var.secrets[each.key].not_before_date, null)
  expiration_date = try(var.secrets[each.key].expiration_date, null)
  tags            = merge(var.tags, try(var.secrets[each.key].tags, {}))
}
