output "resource_group_name" {
  value = module.resource_group.name
}

output "web_app_default_hostname" {
  value = module.web_app.default_hostname
}

output "web_app_slot_default_hostname" {
  value = module.web_app_slot.default_hostname
}

output "key_vault_uri" {
  value = module.key_vault.vault_uri
}

output "storage_account_name" {
  value = module.storage_account.name
}
