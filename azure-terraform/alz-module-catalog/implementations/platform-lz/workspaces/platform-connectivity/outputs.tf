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

output "hub_virtual_network_address_space" {
  description = "Platform_Output_Contracts_IAC-10 connectivity_hub_vnet_address_space."
  value       = try(module.connectivity[0].hub_virtual_network_address_space, [])
}

output "subnet_ids" {
  value = try(module.connectivity[0].subnet_ids, {})
}

output "dns_server_ips" {
  description = "Platform_Output_Contracts_IAC-10 connectivity_dns_server_ips."
  value       = try(module.connectivity[0].dns_server_ips, [])
}

output "network_security_group_ids" {
  description = "Platform_Output_Contracts_IAC-10 connectivity_nsg_baseline_ids."
  value       = try(module.connectivity[0].network_security_group_ids, {})
}

output "route_table_ids" {
  description = "Platform_Output_Contracts_IAC-10 connectivity_spoke_route_table_ids."
  value       = try(module.connectivity[0].route_table_ids, {})
}

output "load_balancer_frontend_private_ip_addresses" {
  description = "Platform_Output_Contracts_IAC-10 connectivity_firewall_ilb_private_ip - pick the entry keyed by the real Trust ILB's load-balancer/frontend key."
  value       = try(module.connectivity[0].load_balancer_frontend_private_ip_addresses, {})
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

output "private_dns_zones_resource_group_id" {
  description = "Platform_Output_Contracts_IAC-10 connectivity_private_dns_resource_group_id - null when zones are reused from an existing landing zone (the current real deployment); see private_dns_zone_resource_group_names for the per-zone RG name in that case."
  value       = try(module.connectivity[0].private_dns_zones_resource_group_id, null)
}

output "ddos_protection_plan_id" {
  value = try(module.connectivity[0].ddos_protection_plan_id, null)
}

output "bastion_id" {
  value = try(module.connectivity[0].bastion_id, null)
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

output "contract_version" {
  description = "Platform_Output_Contracts_IAC-10 connectivity_contract_version."
  value       = "0.1.0"
}
