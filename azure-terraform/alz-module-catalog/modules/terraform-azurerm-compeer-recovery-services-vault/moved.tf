# Resource-address history for the "this" -> semantic-name cleanup.
# Keeps a plan against already-applied state a pure state move (no
# destroy/recreate) instead of replacing every renamed resource.
# Safe to delete once every real workspace has applied past this change.

moved {
  from = azurerm_recovery_services_vault.this
  to   = azurerm_recovery_services_vault.vault
}

moved {
  from = azurerm_backup_policy_vm.this
  to   = azurerm_backup_policy_vm.vm_policy
}

moved {
  from = azurerm_backup_policy_file_share.this
  to   = azurerm_backup_policy_file_share.file_share_policy
}
