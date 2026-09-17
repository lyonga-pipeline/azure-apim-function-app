output "resource_group_name" {
  value = try(module.identity[0].resource_group_name, null)
}

output "platform_identity_ids" {
  value = try(module.identity[0].platform_identity_ids, {})
}

output "platform_identity_principal_ids" {
  value = try(module.identity[0].platform_identity_principal_ids, {})
}

output "platform_identity_client_ids" {
  description = "Platform_Output_Contracts_IAC-10 identity_shared_user_assigned_identity_ids (client_id half - combine with platform_identity_ids/platform_identity_principal_ids per key)."
  value       = try(module.identity[0].platform_identity_client_ids, {})
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

output "disk_encryption_set_ids" {
  value = try(module.identity[0].disk_encryption_set_ids, {})
}

output "disk_encryption_set_identity_principal_ids" {
  value = try(module.identity[0].disk_encryption_set_identity_principal_ids, {})
}

output "contract_version" {
  description = "Platform_Output_Contracts_IAC-10 security_contract_version (this workspace covers SEC-07 of that contract; Sentinel/Defender/Bastion/VPN-certs live in platform-management/platform-connectivity/platform-hybrid-connectivity respectively)."
  value       = "0.1.0"
}
