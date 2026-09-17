output "resource_group_name" {
  description = "Name of the platform-identity-security resource group."
  value       = try(module.identity[0].resource_group_name, null)
}

output "platform_identity_ids" {
  description = "Resource IDs of the shared platform user-assigned identities. Platform_Output_Contracts_IAC-10 identity_shared_user_assigned_identity_ids (id half)."
  value       = try(module.identity[0].platform_identity_ids, {})
}

output "platform_identity_principal_ids" {
  description = "Principal (object) IDs of the shared platform user-assigned identities. Platform_Output_Contracts_IAC-10 identity_shared_user_assigned_identity_ids (principal_id half)."
  value       = try(module.identity[0].platform_identity_principal_ids, {})
}

output "platform_identity_client_ids" {
  description = "Platform_Output_Contracts_IAC-10 identity_shared_user_assigned_identity_ids (client_id half - combine with platform_identity_ids/platform_identity_principal_ids per key)."
  value       = try(module.identity[0].platform_identity_client_ids, {})
}

output "key_vault_id" {
  description = "Resource ID of the shared platform Key Vault. Platform_Output_Contracts_IAC-10 security_platform_key_vault (id half)."
  value       = try(module.identity[0].key_vault_id, null)
}

output "key_vault_name" {
  description = "Name of the shared platform Key Vault."
  value       = try(module.identity[0].key_vault_name, null)
}

output "key_vault_uri" {
  description = "Vault URI of the shared platform Key Vault. Platform_Output_Contracts_IAC-10 security_platform_key_vault (uri half). Reference only, never a secret value."
  value       = try(module.identity[0].key_vault_uri, null)
}

output "key_vault_private_endpoint_id" {
  description = "Resource ID of the shared platform Key Vault's private endpoint, or null if not deployed."
  value       = try(module.identity[0].key_vault_private_endpoint_id, null)
}

output "key_vault_diagnostic_setting_id" {
  description = "ID of the diagnostic setting on the shared platform Key Vault, or null if not enabled."
  value       = try(module.identity[0].key_vault_diagnostic_setting_id, null)
}

output "disk_encryption_set_ids" {
  description = "Disk encryption set resource IDs. Feed to a VM pattern's os_disk.disk_encryption_set_id."
  value       = try(module.identity[0].disk_encryption_set_ids, {})
}

output "disk_encryption_set_identity_principal_ids" {
  description = "Each disk encryption set's identity principal ID."
  value       = try(module.identity[0].disk_encryption_set_identity_principal_ids, {})
}

output "role_assignment_ids" {
  description = "IDs of the role assignments this pattern creates."
  value       = try(module.identity[0].role_assignment_ids, {})
}

output "management_lock_ids" {
  description = "IDs of the management locks (CanNotDelete/ReadOnly) this pattern applies."
  value       = try(module.identity[0].management_lock_ids, {})
}

output "contract_version" {
  description = "Platform_Output_Contracts_IAC-10 security_contract_version (this workspace covers SEC-07 of that contract; Sentinel/Defender/Bastion/VPN-certs live in platform-management/platform-connectivity/platform-hybrid-connectivity respectively)."
  value       = "0.1.0"
}
