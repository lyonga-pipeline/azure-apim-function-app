output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "function_app_name" {
  value = azurerm_windows_function_app.this.name
}

output "function_app_default_hostname" {
  value = azurerm_windows_function_app.this.default_hostname
}

output "storage_account_name" {
  value = azurerm_storage_account.this.name
}

output "key_vault_uri" {
  value = azurerm_key_vault.this.vault_uri
}
