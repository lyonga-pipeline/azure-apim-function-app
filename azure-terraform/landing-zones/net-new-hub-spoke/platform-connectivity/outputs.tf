output "resource_group_name" {
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

output "private_dns_zone_names" {
  value = module.private_dns_zones.names
}

