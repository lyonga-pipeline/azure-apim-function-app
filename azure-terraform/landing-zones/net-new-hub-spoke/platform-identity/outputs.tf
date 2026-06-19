output "resource_group_name" {
  value = module.resource_group.name
}

output "platform_identity_ids" {
  value = { for key, value in module.platform_identities : key => value.id }
}

output "platform_identity_principal_ids" {
  value = { for key, value in module.platform_identities : key => value.principal_id }
}

output "key_vault_id" {
  value = module.key_vault.id
}

output "key_vault_name" {
  value = module.key_vault.name
}

output "key_vault_uri" {
  value = module.key_vault.vault_uri
}

