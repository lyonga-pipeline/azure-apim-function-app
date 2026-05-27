output "resource_group_name" {
  value = module.resource_group.name
}

output "function_app_name" {
  value = module.function_app.name
}

output "key_vault_uri" {
  value = module.key_vault.vault_uri
}

output "storage_account_name" {
  value = module.storage_account.name
}

output "module_version_policy" {
  value = "np2 pins Compeer modules to 2.1.0."
}
