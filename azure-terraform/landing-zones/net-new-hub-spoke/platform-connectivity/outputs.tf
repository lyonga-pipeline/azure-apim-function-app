output "resource_group_name" {
  value = module.resource_group.name
}

output "hub_resource_group_name" {
  value = module.resource_group.name
}

output "hub_virtual_network_id" {
  value = module.hub_vnet.id
}

output "hub_virtual_network_name" {
  value = module.hub_vnet.name
}

output "subnet_ids" {
  value = module.hub_vnet.subnet_ids
}

output "network_security_group_ids" {
  value = { for key, value in module.network_security_groups : key => value.id }
}

output "route_table_ids" {
  value = { for key, value in module.route_tables : key => value.id }
}

output "private_dns_zone_ids" {
  value = module.private_dns_zones.ids
}

output "app_service_private_dns_zone_id" {
  value = try(module.private_dns_zones.ids["app_service"], null)
}

output "key_vault_private_dns_zone_id" {
  value = try(module.private_dns_zones.ids["key_vault"], null)
}

output "storage_blob_private_dns_zone_id" {
  value = try(module.private_dns_zones.ids["storage_blob"], null)
}

output "storage_queue_private_dns_zone_id" {
  value = try(module.private_dns_zones.ids["storage_queue"], null)
}

output "storage_file_private_dns_zone_id" {
  value = try(module.private_dns_zones.ids["storage_file"], null)
}

output "private_dns_zone_names" {
  value = module.private_dns_zones.names
}

output "private_dns_zone_resource_group_names" {
  value = {
    for key, zone in var.private_dns_zones : key => coalesce(try(zone.resource_group_name, null), module.resource_group.name)
  }
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
