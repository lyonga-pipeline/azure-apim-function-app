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

output "hub_virtual_network_address_space" {
  description = "Platform_Output_Contracts_IAC-10 connectivity_hub_vnet_address_space - for route generation, firewall policy context, and spoke UDR authoring."
  value       = module.hub_vnet.address_space
}

output "dns_server_ips" {
  description = "Platform_Output_Contracts_IAC-10 connectivity_dns_server_ips - the hub VNet's own configured DNS servers (domain controllers today; would reflect a Private Resolver inbound endpoint if dns_resolution.mode ever needed to change). This is the value spoke VNets should actually inherit, not var.dns_resolution.dns_server_ips directly - that variable only feeds the dns_resolution_contract precondition."
  value       = module.hub_vnet.dns_servers
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

output "load_balancer_ids" {
  value = { for key, value in module.load_balancers : key => value.id }
}

output "load_balancer_backend_pool_ids" {
  value = { for key, value in module.load_balancers : key => value.backend_pool_ids }
}

output "load_balancer_frontend_private_ip_addresses" {
  description = "Platform_Output_Contracts_IAC-10 connectivity_firewall_ilb_private_ip - every frontend's private IP, keyed \"<load_balancer_key>.<frontend_key>\". This pattern's load_balancers map is caller-defined (no hardcoded 'trust'/'ilb' key), so the specific Palo Alto Trust ILB frontend is whatever key the real tfvars gives it - consumers pick their own entry out of this map rather than this pattern guessing which one is 'the' firewall ILB."
  value = merge({}, [
    for lb_key, lb in module.load_balancers : {
      for fe in lb.frontend_ip_configurations : "${lb_key}.${fe.name}" => fe.private_ip_address
    }
  ]...)
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

output "private_dns_zones_resource_group_id" {
  description = "Platform_Output_Contracts_IAC-10 connectivity_private_dns_resource_group_id - only set when this pattern creates the dedicated RG for fresh zones (module.private_dns_zones_resource_group); null when every zone is existing = true (reused from elsewhere, as in the current real deployment) - see private_dns_zone_resource_group_names for the per-zone RG name in that case."
  value       = try(module.private_dns_zones_resource_group[0].id, null)
}

output "network_watcher_ids" {
  value = { for key, value in azurerm_network_watcher.watcher : key => value.id }
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
  value = module.management_locks.ids
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
