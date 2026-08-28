output "resource_group_name" {
  value = try(module.connectivity[0].resource_group_name, null)
}

output "hub_resource_group_name" {
  value = try(module.connectivity[0].hub_resource_group_name, null)
}

output "hub_virtual_network_id" {
  value = try(module.connectivity[0].hub_virtual_network_id, null)
}

output "hub_virtual_network_name" {
  value = try(module.connectivity[0].hub_virtual_network_name, null)
}

output "subnet_ids" {
  value = try(module.connectivity[0].subnet_ids, {})
}

output "private_dns_zone_ids" {
  value = try(module.connectivity[0].private_dns_zone_ids, {})
}

output "private_dns_zone_names" {
  value = try(module.connectivity[0].private_dns_zone_names, {})
}

output "private_dns_zone_resource_group_names" {
  value = try(module.connectivity[0].private_dns_zone_resource_group_names, {})
}

output "ddos_protection_plan_id" {
  value = try(module.connectivity[0].ddos_protection_plan_id, null)
}

output "private_dns_resolver_id" {
  value = try(module.connectivity[0].private_dns_resolver_id, null)
}

output "bastion_id" {
  value = try(module.connectivity[0].bastion_id, null)
}

output "route_server_ids" {
  value = try(module.connectivity[0].route_server_ids, {})
}

output "route_servers" {
  value = try(module.connectivity[0].route_servers, {})
}

output "route_server_bgp_connections" {
  value = try(module.connectivity[0].route_server_bgp_connections, {})
}

output "local_network_gateways" {
  value = try(module.connectivity[0].local_network_gateways, {})
}

output "network_watcher_flow_logs" {
  value = try(module.connectivity[0].network_watcher_flow_logs, {})
}

output "palo_alto_route_contract" {
  value = try(module.connectivity[0].palo_alto_route_contract, null)
}

output "dns_resolution_contract" {
  value = try(module.connectivity[0].dns_resolution_contract, null)
}
