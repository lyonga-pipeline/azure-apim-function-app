output "resource_group_name" {
  description = "Name of the hybrid-connectivity resource group."
  value       = try(module.hybrid_connectivity[0].resource_group_name, null)
}

output "expressroute_posture" {
  description = "ExpressRoute readiness contract object."
  value       = try(module.hybrid_connectivity[0].expressroute_posture, null)
}

output "expressroute_circuit_ids" {
  description = "Resource IDs of the ExpressRoute circuits."
  value       = try(module.hybrid_connectivity[0].expressroute_circuit_ids, {})
}

output "expressroute_gateway_id" {
  description = "Resource ID of the ExpressRoute virtual network gateway, or null if not deployed. Platform_Output_Contracts_IAC-10 connectivity_expressroute_gateway_id."
  value       = try(module.hybrid_connectivity[0].expressroute_gateway_id, null)
}

output "expressroute_connection_ids" {
  description = "Resource IDs of the ExpressRoute connections."
  value       = try(module.hybrid_connectivity[0].expressroute_connection_ids, {})
}

output "route_server_public_ip_ids" {
  description = "Resource IDs of the Route Server public IPs."
  value       = try(module.hybrid_connectivity[0].route_server_public_ip_ids, {})
}

output "route_server_ids" {
  description = "Resource IDs of the Azure Route Servers."
  value       = try(module.hybrid_connectivity[0].route_server_ids, {})
}

output "route_servers" {
  description = "Route Server attributes keyed by input key for downstream composition."
  value       = try(module.hybrid_connectivity[0].route_servers, {})
}

output "route_server_bgp_connection_ids" {
  description = "Route Server BGP connection IDs keyed by generated key."
  value       = try(module.hybrid_connectivity[0].route_server_bgp_connection_ids, {})
}

output "route_server_bgp_connections" {
  description = "Route Server BGP connection attributes keyed by generated key."
  value       = try(module.hybrid_connectivity[0].route_server_bgp_connections, {})
}

output "contract_version" {
  description = "Platform_Output_Contracts_IAC-10 connectivity_contract_version (this workspace covers Route Server now and ExpressRoute later; the hub VNet itself is platform-connectivity)."
  value       = "0.1.0"
}
