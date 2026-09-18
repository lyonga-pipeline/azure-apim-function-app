output "resource_group_name" {
  description = "Name of the workload spoke's resource group."
  value       = module.resource_group.name
}

output "spoke_resource_group_name" {
  description = "Alias of resource_group_name - the spoke resource group. Platform_Output_Contracts_IAC-10 spoke_resource_group_ids maps here (one resource group per workload-spoke workspace in this catalog's per-app template model)."
  value       = module.resource_group.name
}

output "spoke_virtual_network_id" {
  description = "Resource ID of the spoke virtual network. Platform_Output_Contracts_IAC-10 spoke_vnet_id."
  value       = module.spoke_vnet.id
}

output "spoke_virtual_network_name" {
  description = "Name of the spoke virtual network."
  value       = module.spoke_vnet.name
}

output "subnet_ids" {
  description = "Resource IDs of the spoke VNet's subnets, keyed by subnet name. Platform_Output_Contracts_IAC-10 spoke_subnet_ids."
  value       = module.spoke_vnet.subnet_ids
}

output "app_service_integration_subnet_id" {
  description = "Convenience accessor: subnet_ids[\"app_integration\"], or null if that subnet key isn't configured."
  value       = try(module.spoke_vnet.subnet_ids["app_integration"], null)
}

output "private_endpoint_subnet_id" {
  description = "Convenience accessor: subnet_ids[\"private_endpoints\"], or null if that subnet key isn't configured."
  value       = try(module.spoke_vnet.subnet_ids["private_endpoints"], null)
}

output "workload_identity_id" {
  description = "Resource ID of the workload's user-assigned managed identity, or null if not deployed. Platform_Output_Contracts_IAC-10 spoke_user_assigned_identity_ids (id half)."
  value       = try(module.workload_identity[0].id, null)
}

output "workload_identity_client_id" {
  description = "Client (application) ID of the workload's user-assigned identity, or null if not deployed. Platform_Output_Contracts_IAC-10 spoke_user_assigned_identity_ids (client_id half)."
  value       = try(module.workload_identity[0].client_id, null)
}

output "workload_identity_principal_id" {
  description = "Principal (object) ID of the workload's user-assigned identity, or null if not deployed. Platform_Output_Contracts_IAC-10 spoke_user_assigned_identity_ids (principal_id half)."
  value       = try(module.workload_identity[0].principal_id, null)
}

output "workload_key_vault_id" {
  description = "Resource ID of the workload Key Vault, or null if not deployed. Platform_Output_Contracts_IAC-10 spoke_key_vault (id half)."
  value       = try(module.workload_key_vault[0].id, null)
}

output "workload_key_vault_uri" {
  description = "Platform_Output_Contracts_IAC-10 spoke_key_vault (vault_uri half - combine with workload_key_vault_id). Reference only, never a secret value."
  value       = try(module.workload_key_vault[0].vault_uri, null)
}

output "workload_key_vault_name" {
  description = "Name of the workload Key Vault, or null if not deployed."
  value       = try(module.workload_key_vault[0].name, null)
}

output "workload_key_vault_private_endpoint_id" {
  description = "Resource ID of the workload Key Vault's private endpoint, or null if not deployed."
  value       = try(module.workload_key_vault_private_endpoint[0].id, null)
}

output "workload_key_vault_diagnostic_setting_id" {
  description = "ID of the diagnostic setting on the workload Key Vault, or null if not enabled."
  value       = try(module.workload_key_vault_diagnostics[0].id, null)
}

output "spoke_to_hub_peering_id" {
  description = "Resource ID of the spoke-to-hub VNet peering, or null if peering is managed outside this pattern (e.g. by network-peering)."
  value       = try(module.spoke_to_hub_peering[0].id, null)
}

output "network_security_group_ids" {
  description = "Resource IDs of the spoke NSGs, keyed the same as var.network_security_groups."
  value       = { for key, value in module.network_security_groups : key => value.id }
}

output "route_table_ids" {
  description = "Resource IDs of the spoke route tables, keyed the same as var.route_tables."
  value       = { for key, value in module.route_tables : key => value.id }
}

output "role_assignment_ids" {
  description = "IDs of the role assignments this pattern creates."
  value       = module.role_assignments.ids
}

output "management_lock_ids" {
  description = "IDs of the management locks (CanNotDelete/ReadOnly) this pattern applies."
  value       = module.management_locks.ids
}

output "diagnostic_setting_ids" {
  description = "IDs of the diagnostic settings this pattern creates, keyed the same as var.diagnostic_settings."
  value       = { for key, value in module.diagnostic_settings : key => value.id }
}

output "private_endpoint_ids" {
  description = "Workload private endpoint IDs keyed by input key."
  value       = { for k, v in module.private_endpoints : k => v.id }
}

output "workload_storage_account_ids" {
  description = "Resource IDs of the workload storage accounts, keyed the same as var.workload_storage_accounts."
  value       = { for k, v in module.workload_storage_accounts : k => v.id }
}

output "workload_storage_account_names" {
  description = "Names of the workload storage accounts, keyed the same as var.workload_storage_accounts."
  value       = { for k, v in module.workload_storage_accounts : k => v.name }
}

output "workload_storage_account_primary_endpoints" {
  description = "Primary service endpoints (blob/queue/table/file) per workload storage account, keyed the same as var.workload_storage_accounts."
  value       = { for k, v in module.workload_storage_accounts : k => v.primary_endpoints }
}

output "workload_storage_diagnostic_setting_ids" {
  description = "IDs of the diagnostic settings on the workload storage accounts."
  value       = { for k, v in module.workload_storage_diagnostics : k => v.id }
}

output "workload_storage_private_endpoint_ids" {
  description = "Resource IDs of the private endpoints created for the workload storage accounts."
  value       = { for k, v in module.workload_storage_private_endpoints : k => v.id }
}
