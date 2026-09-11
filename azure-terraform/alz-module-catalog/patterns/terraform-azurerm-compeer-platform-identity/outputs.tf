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

output "key_vault_private_endpoint_id" {
  value = try(module.key_vault_private_endpoint[0].id, null)
}

output "key_vault_diagnostic_setting_id" {
  value = try(module.key_vault_diagnostics[0].id, null)
}

output "disk_encryption_set_ids" {
  description = "Disk encryption set resource IDs keyed by disk_encryption_sets key. Feed to a VM pattern's os_disk.disk_encryption_set_id."
  value       = { for key, value in module.disk_encryption_sets : key => value.id }
}

output "disk_encryption_set_identity_principal_ids" {
  description = "Each disk encryption set's identity principal ID. Grant it Key Vault Crypto Service Encryption User on the source key (identity_role_assignments / external_role_assignments) before the first disk uses it."
  value       = { for key, value in module.disk_encryption_sets : key => value.identity_principal_id }
}

output "role_assignment_ids" {
  value = module.role_assignments.ids
}

output "management_lock_ids" {
  value = module.management_locks.ids
}
