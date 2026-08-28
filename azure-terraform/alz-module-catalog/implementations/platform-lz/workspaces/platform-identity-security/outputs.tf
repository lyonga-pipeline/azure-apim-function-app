output "resource_group_name" {
  value = try(module.identity[0].resource_group_name, null)
}

output "platform_identity_ids" {
  value = try(module.identity[0].platform_identity_ids, {})
}

output "platform_identity_principal_ids" {
  value = try(module.identity[0].platform_identity_principal_ids, {})
}

output "key_vault_id" {
  value = try(module.identity[0].key_vault_id, null)
}

output "key_vault_name" {
  value = try(module.identity[0].key_vault_name, null)
}

output "key_vault_uri" {
  value = try(module.identity[0].key_vault_uri, null)
}

output "key_vault_private_endpoint_id" {
  value = try(module.identity[0].key_vault_private_endpoint_id, null)
}
