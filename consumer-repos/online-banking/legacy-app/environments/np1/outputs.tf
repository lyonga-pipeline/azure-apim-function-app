output "resource_group_name" {
  value = module.legacy_app.resource_group_name
}

output "function_app_name" {
  value = module.legacy_app.function_app_name
}

output "function_app_default_hostname" {
  value = module.legacy_app.function_app_default_hostname
}

output "storage_account_name" {
  value = module.legacy_app.storage_account_name
}

output "key_vault_uri" {
  value = module.legacy_app.key_vault_uri
}
