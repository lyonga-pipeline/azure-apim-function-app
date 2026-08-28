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

output "ddos_protection_plan_id" {
  value = local.ddos_protection_plan_id
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

output "public_ip_ids" {
  value = { for key, value in module.public_ips : key => value.id }
}

output "public_ip_addresses" {
  value = { for key, value in module.public_ips : key => value.ip_address }
}

output "route_server_public_ip_ids" {
  value = { for key, value in module.route_server_public_ips : key => value.id }
}

output "route_server_ids" {
  value = module.route_server.ids
}

output "route_servers" {
  value = module.route_server.route_servers
}

output "route_server_bgp_connection_ids" {
  value = module.route_server.bgp_connection_ids
}

output "route_server_bgp_connections" {
  value = module.route_server.bgp_connections
}

output "load_balancer_ids" {
  value = { for key, value in module.load_balancers : key => value.id }
}

output "load_balancer_backend_pool_ids" {
  value = { for key, value in module.load_balancers : key => value.backend_pool_ids }
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

output "private_dns_resolver_id" {
  value = try(module.private_dns_resolver[0].id, null)
}

output "private_dns_resolver_inbound_endpoint_ids" {
  value = try(module.private_dns_resolver[0].inbound_endpoint_ids, {})
}

output "private_dns_resolver_outbound_endpoint_ids" {
  value = try(module.private_dns_resolver[0].outbound_endpoint_ids, {})
}

output "bastion_id" {
  value = try(module.bastion[0].id, null)
}

output "bastion_public_ip_id" {
  value = try(module.bastion[0].public_ip_id, null)
}

output "private_dns_zone_resource_group_names" {
  value = {
    for key, zone in var.private_dns_zones : key => coalesce(try(zone.resource_group_name, null), module.resource_group.name)
  }
}

output "network_watcher_ids" {
  value = { for key, value in azurerm_network_watcher.this : key => value.id }
}

output "local_network_gateway_ids" {
  value = module.local_network_gateways.ids
}

output "local_network_gateways" {
  value = module.local_network_gateways.gateways
}

output "network_watcher_flow_log_ids" {
  value = module.network_watcher_flow_logs.ids
}

output "network_watcher_flow_logs" {
  value = module.network_watcher_flow_logs.flow_logs
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

output "palo_alto_route_contract" {
  value = terraform_data.palo_alto_route_contract.output
}

output "dns_resolution_contract" {
  value = terraform_data.dns_resolution_contract.output
}
