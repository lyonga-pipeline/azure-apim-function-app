output "resource_group_name" {
  value = try(module.shared_services[0].resource_group_name, null)
}

output "shared_services_virtual_network_id" {
  value = try(module.shared_services[0].shared_services_virtual_network_id, null)
}

output "shared_services_virtual_network_name" {
  value = try(module.shared_services[0].shared_services_virtual_network_name, null)
}

output "subnet_ids" {
  value = try(module.shared_services[0].subnet_ids, {})
}

output "private_endpoint_subnet_id" {
  value = try(module.shared_services[0].private_endpoint_subnet_id, null)
}

output "platform_identity_principal_id" {
  value = try(module.shared_services[0].platform_identity_principal_id, null)
}

output "platform_key_vault_id" {
  value = try(module.shared_services[0].platform_key_vault_id, null)
}

output "platform_key_vault_private_endpoint_id" {
  value = try(module.shared_services[0].platform_key_vault_private_endpoint_id, null)
}

output "network_security_group_ids" {
  value = try(module.shared_services[0].network_security_group_ids, {})
}

output "route_table_ids" {
  value = try(module.shared_services[0].route_table_ids, {})
}

output "spoke_to_hub_peering_id" {
  value = try(module.shared_services[0].spoke_to_hub_peering_id, null)
}
