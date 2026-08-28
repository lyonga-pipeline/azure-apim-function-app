output "vnet_id" { value = module.vnet.resource_id }
output "subnets" { value = module.vnet.subnets }
output "route_table_id" { value = module.route_table.resource_id }
output "workload_identity_id" { value = try(module.workload_identity[0].resource_id, null) }
output "workload_identity_principal_id" { value = try(module.workload_identity[0].principal_id, null) }
output "workload_key_vault_id" { value = try(module.workload_key_vault[0].id, null) }
output "workload_key_vault_private_endpoint_id" { value = try(module.workload_key_vault_private_endpoint[0].id, null) }
