output "resource_group_name" {
  value = module.shared_services.resource_group_name
}

output "shared_services_virtual_network_id" {
  value = module.shared_services.spoke_virtual_network_id
}

output "shared_services_virtual_network_name" {
  value = module.shared_services.spoke_virtual_network_name
}

output "subnet_ids" {
  value = module.shared_services.subnet_ids
}

output "private_endpoint_subnet_id" {
  value = module.shared_services.private_endpoint_subnet_id
}

output "platform_identity_principal_id" {
  value = module.shared_services.workload_identity_principal_id
}

output "platform_key_vault_id" {
  value = module.shared_services.workload_key_vault_id
}

output "platform_key_vault_private_endpoint_id" {
  value = module.shared_services.workload_key_vault_private_endpoint_id
}

output "network_security_group_ids" {
  value = module.shared_services.network_security_group_ids
}

output "route_table_ids" {
  value = module.shared_services.route_table_ids
}

output "spoke_to_hub_peering_id" {
  value = module.shared_services.spoke_to_hub_peering_id
}
