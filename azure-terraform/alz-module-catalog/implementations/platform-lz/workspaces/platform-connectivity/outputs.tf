output "resource_group_name" {
  description = "Name of the connectivity (hub) resource group."
  value       = try(module.connectivity[0].resource_group_name, null)
}

output "hub_resource_group_name" {
  description = "Alias of resource_group_name - the hub resource group."
  value       = try(module.connectivity[0].hub_resource_group_name, null)
}

output "hub_virtual_network_id" {
  description = "Resource ID of the hub virtual network. Platform_Output_Contracts_IAC-10 connectivity_hub_vnet_id."
  value       = try(module.connectivity[0].hub_virtual_network_id, null)
}

output "hub_virtual_network_name" {
  description = "Name of the hub virtual network. Platform_Output_Contracts_IAC-10 connectivity_hub_vnet_name."
  value       = try(module.connectivity[0].hub_virtual_network_name, null)
}

output "hub_virtual_network_address_space" {
  description = "Platform_Output_Contracts_IAC-10 connectivity_hub_vnet_address_space."
  value       = try(module.connectivity[0].hub_virtual_network_address_space, [])
}

output "subnet_ids" {
  description = "Resource IDs of the hub VNet's subnets, keyed by subnet name. Platform_Output_Contracts_IAC-10 connectivity_hub_subnet_ids."
  value       = try(module.connectivity[0].subnet_ids, {})
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

output "load_balancer_ids" {
  description = "Resource IDs of the load balancers this pattern creates."
  value       = try(module.connectivity[0].load_balancer_ids, {})
}

output "load_balancer_backend_pool_ids" {
  description = "Backend address pool IDs per load balancer."
  value       = try(module.connectivity[0].load_balancer_backend_pool_ids, {})
}

output "load_balancer_frontend_private_ip_addresses" {
  description = "Platform_Output_Contracts_IAC-10 connectivity_firewall_ilb_private_ip - pick the entry keyed by the real Trust ILB's load-balancer/frontend key."
  value       = try(module.connectivity[0].load_balancer_frontend_private_ip_addresses, {})
}

output "private_dns_zone_ids" {
  description = "Resource IDs of the private DNS zones, keyed by zone key. Platform_Output_Contracts_IAC-10 connectivity_private_dns_zone_ids."
  value       = try(module.connectivity[0].private_dns_zone_ids, {})
}

output "app_service_private_dns_zone_id" {
  description = "Convenience accessor: private_dns_zone_ids[\"app_service\"], or null if that zone key isn't configured."
  value       = try(module.connectivity[0].app_service_private_dns_zone_id, null)
}

output "key_vault_private_dns_zone_id" {
  description = "Convenience accessor: private_dns_zone_ids[\"key_vault\"], or null if that zone key isn't configured."
  value       = try(module.connectivity[0].key_vault_private_dns_zone_id, null)
}

output "storage_blob_private_dns_zone_id" {
  description = "Convenience accessor: private_dns_zone_ids[\"storage_blob\"], or null if that zone key isn't configured."
  value       = try(module.connectivity[0].storage_blob_private_dns_zone_id, null)
}

output "storage_queue_private_dns_zone_id" {
  description = "Convenience accessor: private_dns_zone_ids[\"storage_queue\"], or null if that zone key isn't configured."
  value       = try(module.connectivity[0].storage_queue_private_dns_zone_id, null)
}

output "storage_file_private_dns_zone_id" {
  description = "Convenience accessor: private_dns_zone_ids[\"storage_file\"], or null if that zone key isn't configured."
  value       = try(module.connectivity[0].storage_file_private_dns_zone_id, null)
}

output "private_dns_zone_names" {
  description = "Names of the private DNS zones, keyed the same as private_dns_zone_ids."
  value       = try(module.connectivity[0].private_dns_zone_names, {})
}

output "private_dns_zone_resource_group_names" {
  description = "Resource group name hosting each private DNS zone, keyed by zone key."
  value       = try(module.connectivity[0].private_dns_zone_resource_group_names, {})
}

output "private_dns_zones_resource_group_id" {
  description = "Platform_Output_Contracts_IAC-10 connectivity_private_dns_resource_group_id - null when zones are reused from an existing landing zone (the current real deployment); see private_dns_zone_resource_group_names for the per-zone RG name in that case."
  value       = try(module.connectivity[0].private_dns_zones_resource_group_id, null)
}

output "ddos_protection_plan_id" {
  description = "Resource ID of the DDoS Network Protection plan associated with the hub VNet, or null if not enabled."
  value       = try(module.connectivity[0].ddos_protection_plan_id, null)
}

output "bastion_id" {
  description = "Resource ID of the Azure Bastion host, or null if not deployed. Platform_Output_Contracts_IAC-10 security_bastion_host_id."
  value       = try(module.connectivity[0].bastion_id, null)
}

output "bastion_public_ip_id" {
  description = "Resource ID of the Bastion host's public IP, or null if not deployed."
  value       = try(module.connectivity[0].bastion_public_ip_id, null)
}

output "network_watcher_ids" {
  description = "Resource IDs of the Network Watchers this pattern manages, keyed by region."
  value       = try(module.connectivity[0].network_watcher_ids, {})
}

output "network_watcher_flow_log_ids" {
  description = "Resource IDs of the NSG flow log configurations."
  value       = try(module.connectivity[0].network_watcher_flow_log_ids, {})
}

output "network_watcher_flow_logs" {
  description = "Full flow-log detail (storage account, retention, traffic analytics) per configured flow log."
  value       = try(module.connectivity[0].network_watcher_flow_logs, {})
}

output "role_assignment_ids" {
  description = "IDs of the role assignments this pattern creates."
  value       = try(module.connectivity[0].role_assignment_ids, {})
}

output "management_lock_ids" {
  description = "IDs of the management locks (CanNotDelete/ReadOnly) this pattern applies."
  value       = try(module.connectivity[0].management_lock_ids, {})
}

output "diagnostic_setting_ids" {
  description = "IDs of the diagnostic settings this pattern creates."
  value       = try(module.connectivity[0].diagnostic_setting_ids, {})
}

output "palo_alto_route_contract" {
  description = "Palo Alto route-precondition contract object."
  value       = try(module.connectivity[0].palo_alto_route_contract, null)
}

output "dns_resolution_contract" {
  description = "DNS resolution decision-record contract object."
  value       = try(module.connectivity[0].dns_resolution_contract, null)
}

output "contract_version" {
  description = "Platform_Output_Contracts_IAC-10 connectivity_contract_version."
  value       = "0.1.0"
}
