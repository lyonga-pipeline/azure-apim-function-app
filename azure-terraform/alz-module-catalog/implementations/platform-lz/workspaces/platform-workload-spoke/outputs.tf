output "resource_group_name" {
  value = try(module.workload_spoke[0].resource_group_name, null)
}

output "spoke_resource_group_name" {
  value = try(module.workload_spoke[0].spoke_resource_group_name, null)
}

output "spoke_virtual_network_id" {
  value = try(module.workload_spoke[0].spoke_virtual_network_id, null)
}

output "spoke_virtual_network_name" {
  value = try(module.workload_spoke[0].spoke_virtual_network_name, null)
}

output "subnet_ids" {
  value = try(module.workload_spoke[0].subnet_ids, {})
}

output "private_endpoint_subnet_id" {
  value = try(module.workload_spoke[0].private_endpoint_subnet_id, null)
}

output "workload_identity_id" {
  description = "Platform_Output_Contracts_IAC-10 spoke_user_assigned_identity_ids (id half)."
  value       = try(module.workload_spoke[0].workload_identity_id, null)
}

output "workload_identity_principal_id" {
  value = try(module.workload_spoke[0].workload_identity_principal_id, null)
}

output "workload_identity_client_id" {
  description = "Platform_Output_Contracts_IAC-10 spoke_user_assigned_identity_ids (client_id half)."
  value       = try(module.workload_spoke[0].workload_identity_client_id, null)
}

output "workload_key_vault_id" {
  value = try(module.workload_spoke[0].workload_key_vault_id, null)
}

output "workload_key_vault_uri" {
  description = "Platform_Output_Contracts_IAC-10 spoke_key_vault (vault_uri half). Reference only, never a secret value."
  value       = try(module.workload_spoke[0].workload_key_vault_uri, null)
}

output "workload_key_vault_private_endpoint_id" {
  value = try(module.workload_spoke[0].workload_key_vault_private_endpoint_id, null)
}

output "spoke_log_analytics_workspace_id" {
  description = "Platform_Output_Contracts_IAC-10 spoke_log_analytics_workspace_id - passthrough of management's log_analytics_workspace_id, so an application root never needs a state-sharing grant on platform-management for one string."
  value       = local.log_analytics_workspace_id
}

output "spoke_mandatory_tag_keys" {
  description = "Platform_Output_Contracts_IAC-10 spoke_mandatory_tag_keys - passthrough of governance's mandatory_tag_keys."
  value       = local.mandatory_tag_keys
}

output "contract_version" {
  description = "Platform_Output_Contracts_IAC-10 spoke_contract_version."
  value       = "0.1.0"
}
