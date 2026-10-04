output "resource_group_name" {
  description = "Name of the hybrid-connectivity resource group."
  value       = module.resource_group.name
}

output "expressroute_circuit_ids" {
  description = "Resource IDs of the ExpressRoute circuits, keyed the same as var.expressroute_circuits."
  value       = { for key, value in module.expressroute_circuits : key => value.id }
}

output "expressroute_gateway_id" {
  description = "Resource ID of the ExpressRoute virtual network gateway, or null if not deployed. Platform_Output_Contracts_IAC-10 connectivity_expressroute_gateway_id."
  value       = try(module.expressroute_gateway[0].id, null)
}

output "expressroute_connection_ids" {
  description = "Resource IDs of the ExpressRoute connections, keyed the same as var.expressroute_connections."
  value       = { for key, value in module.expressroute_connections : key => value.id }
}

output "expressroute_posture" {
  description = "ExpressRoute readiness contract object - see the expressroute_contract terraform_data resource for what it asserts."
  value       = terraform_data.expressroute_contract.output
}

output "route_server_public_ip_ids" {
  description = "Resource IDs of the Route Server public IPs, keyed the same as var.route_server_public_ips."
  value       = { for key, value in module.route_server_public_ips : key => value.id }
}

output "route_server_ids" {
  description = "Resource IDs of the Azure Route Servers, keyed the same as var.route_servers."
  value       = module.route_servers.ids
}

output "route_servers" {
  description = "Route Server attributes keyed by input key for downstream composition."
  value       = module.route_servers.route_servers
}

output "route_server_bgp_connection_ids" {
  description = "Route Server BGP connection IDs keyed by generated key."
  value       = module.route_servers.bgp_connection_ids
}

output "route_server_bgp_connections" {
  description = "Route Server BGP connection attributes keyed by generated key."
  value       = module.route_servers.bgp_connections
}
