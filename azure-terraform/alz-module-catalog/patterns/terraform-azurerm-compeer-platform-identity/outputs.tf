output "resource_group_name" {
  description = "Name of the platform-identity-security resource group."
  value       = module.resource_group.name
}

output "platform_identity_ids" {
  description = "Resource IDs of the shared platform user-assigned identities, keyed by input key. Platform_Output_Contracts_IAC-10 identity_shared_user_assigned_identity_ids (id half)."
  value       = { for key, value in module.platform_identities : key => value.id }
}

output "platform_identity_principal_ids" {
  description = "Principal (object) IDs of the shared platform user-assigned identities, keyed by input key. Platform_Output_Contracts_IAC-10 identity_shared_user_assigned_identity_ids (principal_id half)."
  value       = { for key, value in module.platform_identities : key => value.principal_id }
}

output "platform_identity_client_ids" {
  description = "Client (application) IDs of the shared platform user-assigned identities, keyed by input key - the piece Platform_Output_Contracts_IAC-10's identity_shared_user_assigned_identity_ids (map(object({id, principal_id, client_id}))) needs that wasn't published before."
  value       = { for key, value in module.platform_identities : key => value.client_id }
}

output "key_vault_id" {
  description = "Resource ID of the shared platform Key Vault. Platform_Output_Contracts_IAC-10 security_platform_key_vault (id half)."
  value       = module.key_vault.id
}

output "key_vault_name" {
  description = "Name of the shared platform Key Vault."
  value       = module.key_vault.name
}

output "key_vault_uri" {
  description = "Vault URI of the shared platform Key Vault. Platform_Output_Contracts_IAC-10 security_platform_key_vault (uri half). Reference only, never a secret value."
  value       = module.key_vault.vault_uri
}

output "key_vault_private_endpoint_id" {
  description = "Resource ID of the shared platform Key Vault's private endpoint, or null if not deployed."
  value       = try(module.key_vault_private_endpoint[0].id, null)
}

output "key_vault_diagnostic_setting_id" {
  description = "ID of the diagnostic setting on the shared platform Key Vault, or null if not enabled."
  value       = try(module.key_vault_diagnostics[0].id, null)
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
  description = "IDs of the role assignments this pattern creates."
  value       = module.role_assignments.ids
}

output "management_lock_ids" {
  description = "IDs of the management locks (CanNotDelete/ReadOnly) this pattern applies."
  value       = module.management_locks.ids
}
