output "resource_group_name" {
  value = module.resource_group.name
}

output "spoke_resource_group_name" {
  value = module.resource_group.name
}

output "spoke_virtual_network_id" {
  value = module.spoke_vnet.id
}

output "spoke_virtual_network_name" {
  value = module.spoke_vnet.name
}

output "subnet_ids" {
  value = module.spoke_vnet.subnet_ids
}

output "app_service_integration_subnet_id" {
  value = try(module.spoke_vnet.subnet_ids["app_integration"], null)
}

output "private_endpoint_subnet_id" {
  value = try(module.spoke_vnet.subnet_ids["private_endpoints"], null)
}

output "workload_identity_id" {
  value = try(module.workload_identity[0].id, null)
}

output "workload_identity_client_id" {
  value = try(module.workload_identity[0].client_id, null)
}

output "workload_identity_principal_id" {
  value = try(module.workload_identity[0].principal_id, null)
}

output "workload_key_vault_id" {
  value = try(module.workload_key_vault[0].id, null)
}

output "workload_key_vault_name" {
  value = try(module.workload_key_vault[0].name, null)
}

output "workload_key_vault_private_endpoint_id" {
  value = try(module.workload_key_vault_private_endpoint[0].id, null)
}

output "workload_key_vault_diagnostic_setting_id" {
  value = try(module.workload_key_vault_diagnostics[0].id, null)
}

output "spoke_to_hub_peering_id" {
  value = try(module.spoke_to_hub_peering[0].id, null)
}

output "network_security_group_ids" {
  value = { for key, value in module.network_security_groups : key => value.id }
}

output "route_table_ids" {
  value = { for key, value in module.route_tables : key => value.id }
}

output "role_assignment_ids" {
  value = module.role_assignments.ids
}

output "management_lock_ids" {
  value = { for key, value in azurerm_management_lock.this : key => value.id }
}

output "diagnostic_setting_ids" {
  value = { for key, value in module.diagnostic_settings : key => value.id }
}
