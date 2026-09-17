output "resource_group_name" {
  description = "Name of the workload spoke's resource group."
  value       = try(module.workload_spoke[0].resource_group_name, null)
}

output "spoke_resource_group_name" {
  description = "Alias of resource_group_name. Platform_Output_Contracts_IAC-10 spoke_resource_group_ids."
  value       = try(module.workload_spoke[0].spoke_resource_group_name, null)
}

output "spoke_virtual_network_id" {
  description = "Resource ID of the spoke virtual network. Platform_Output_Contracts_IAC-10 spoke_vnet_id."
  value       = try(module.workload_spoke[0].spoke_virtual_network_id, null)
}

output "spoke_virtual_network_name" {
  description = "Name of the spoke virtual network."
  value       = try(module.workload_spoke[0].spoke_virtual_network_name, null)
}

output "subnet_ids" {
  description = "Resource IDs of the spoke VNet's subnets. Platform_Output_Contracts_IAC-10 spoke_subnet_ids."
  value       = try(module.workload_spoke[0].subnet_ids, {})
}

output "app_service_integration_subnet_id" {
  description = "Convenience accessor: subnet_ids[\"app_integration\"], or null if that subnet key isn't configured."
  value       = try(module.workload_spoke[0].app_service_integration_subnet_id, null)
}

output "private_endpoint_subnet_id" {
  description = "Convenience accessor: subnet_ids[\"private_endpoints\"], or null if that subnet key isn't configured."
  value       = try(module.workload_spoke[0].private_endpoint_subnet_id, null)
}

output "workload_identity_id" {
  description = "Platform_Output_Contracts_IAC-10 spoke_user_assigned_identity_ids (id half)."
  value       = try(module.workload_spoke[0].workload_identity_id, null)
}

output "workload_identity_principal_id" {
  description = "Platform_Output_Contracts_IAC-10 spoke_user_assigned_identity_ids (principal_id half)."
  value       = try(module.workload_spoke[0].workload_identity_principal_id, null)
}

output "workload_identity_client_id" {
  description = "Platform_Output_Contracts_IAC-10 spoke_user_assigned_identity_ids (client_id half)."
  value       = try(module.workload_spoke[0].workload_identity_client_id, null)
}

output "workload_key_vault_id" {
  description = "Resource ID of the workload Key Vault, or null if not deployed. Platform_Output_Contracts_IAC-10 spoke_key_vault (id half)."
  value       = try(module.workload_spoke[0].workload_key_vault_id, null)
}

output "workload_key_vault_uri" {
  description = "Platform_Output_Contracts_IAC-10 spoke_key_vault (vault_uri half). Reference only, never a secret value."
  value       = try(module.workload_spoke[0].workload_key_vault_uri, null)
}

output "workload_key_vault_name" {
  description = "Name of the workload Key Vault, or null if not deployed."
  value       = try(module.workload_spoke[0].workload_key_vault_name, null)
}

output "workload_key_vault_private_endpoint_id" {
  description = "Resource ID of the workload Key Vault's private endpoint, or null if not deployed."
  value       = try(module.workload_spoke[0].workload_key_vault_private_endpoint_id, null)
}

output "workload_key_vault_diagnostic_setting_id" {
  description = "ID of the diagnostic setting on the workload Key Vault, or null if not enabled."
  value       = try(module.workload_spoke[0].workload_key_vault_diagnostic_setting_id, null)
}

output "spoke_to_hub_peering_id" {
  description = "Resource ID of the spoke-to-hub VNet peering, or null if peering is managed outside this pattern (e.g. by network-peering)."
  value       = try(module.workload_spoke[0].spoke_to_hub_peering_id, null)
}

output "network_security_group_ids" {
  description = "Resource IDs of the spoke NSGs."
  value       = try(module.workload_spoke[0].network_security_group_ids, {})
}

output "route_table_ids" {
  description = "Resource IDs of the spoke route tables."
  value       = try(module.workload_spoke[0].route_table_ids, {})
}

output "role_assignment_ids" {
  description = "IDs of the role assignments this pattern creates."
  value       = try(module.workload_spoke[0].role_assignment_ids, {})
}

output "management_lock_ids" {
  description = "IDs of the management locks (CanNotDelete/ReadOnly) this pattern applies."
  value       = try(module.workload_spoke[0].management_lock_ids, {})
}

output "diagnostic_setting_ids" {
  description = "IDs of the diagnostic settings this pattern creates."
  value       = try(module.workload_spoke[0].diagnostic_setting_ids, {})
}

output "private_endpoint_ids" {
  description = "Workload private endpoint IDs keyed by input key."
  value       = try(module.workload_spoke[0].private_endpoint_ids, {})
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
