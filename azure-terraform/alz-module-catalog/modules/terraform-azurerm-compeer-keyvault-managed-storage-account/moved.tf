# Resource-address history for the "this" -> semantic-name cleanup.
# Keeps a plan against already-applied state a pure state move (no
# destroy/recreate) instead of replacing every renamed resource.
# Safe to delete once every real workspace has applied past this change.

moved {
  from = azurerm_key_vault_managed_storage_account.this
  to   = azurerm_key_vault_managed_storage_account.managed_storage_account
}

moved {
  from = azurerm_key_vault_managed_storage_account_sas_token_definition.this
  to   = azurerm_key_vault_managed_storage_account_sas_token_definition.sas_token
}
