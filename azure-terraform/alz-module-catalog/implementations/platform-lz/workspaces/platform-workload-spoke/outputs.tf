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

output "workload_identity_principal_id" {
  value = try(module.workload_spoke[0].workload_identity_principal_id, null)
}

output "workload_key_vault_id" {
  value = try(module.workload_spoke[0].workload_key_vault_id, null)
}

output "workload_key_vault_private_endpoint_id" {
  value = try(module.workload_spoke[0].workload_key_vault_private_endpoint_id, null)
}
