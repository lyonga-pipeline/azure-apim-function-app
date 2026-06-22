output "resource_group_name" {
  value = module.clientsync_function_app.resource_group_name
}

output "function_app_name" {
  value = module.clientsync_function_app.function_app_name
}

output "function_app_default_hostname" {
  value = module.clientsync_function_app.function_app_default_hostname
}

output "key_vault_uri" {
  value = module.clientsync_function_app.key_vault_uri
}

output "storage_account_name" {
  value = module.clientsync_function_app.storage_account_name
}

output "private_endpoint_ids" {
  value = module.clientsync_function_app.private_endpoint_ids
}

