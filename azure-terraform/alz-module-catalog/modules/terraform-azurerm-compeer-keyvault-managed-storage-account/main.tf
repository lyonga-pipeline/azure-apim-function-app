resource "azurerm_key_vault_managed_storage_account" "this" {
  name                         = var.name
  key_vault_id                 = var.key_vault_id
  storage_account_id           = var.storage_account_id
  storage_account_key          = var.storage_account_key
  regenerate_key_automatically = var.regenerate_key_automatically
  regeneration_period          = var.regeneration_period
  tags                         = var.tags
}

resource "azurerm_key_vault_managed_storage_account_sas_token_definition" "this" {
  for_each = var.sas_token_definitions

  name                       = each.key
  managed_storage_account_id = azurerm_key_vault_managed_storage_account.this.id
  sas_template_uri           = each.value.sas_template_uri
  sas_type                   = each.value.sas_type
  validity_period            = each.value.validity_period
  tags                       = merge(var.tags, each.value.tags)
}
