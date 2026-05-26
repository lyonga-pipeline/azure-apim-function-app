output "resource_group_name" {
  value = module.resource_group.name
}

output "function_app_name" {
  value = module.function_app.name
}

output "function_app_default_hostname" {
  value = module.function_app.default_hostname
}

output "key_vault_uri" {
  value = module.key_vault.vault_uri
}

output "storage_account_name" {
  value = module.storage_account.name
}

output "private_endpoint_ids" {
  value = { for key, endpoint in module.private_endpoints : key => endpoint.id }
}
