output "resource_group_name" {
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
