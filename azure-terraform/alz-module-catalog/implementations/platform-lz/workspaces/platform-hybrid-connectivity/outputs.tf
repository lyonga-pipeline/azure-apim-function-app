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

output "vpn_posture" {
  description = "Site-to-site VPN readiness contract object."
  value       = try(module.hybrid_connectivity[0].vpn_posture, null)
}

output "vpn_gateway_public_ip_ids" {
  description = "Resource IDs of the VPN gateway public IPs."
  value       = try(module.hybrid_connectivity[0].vpn_gateway_public_ip_ids, {})
}

output "vpn_gateway_id" {
  description = "Resource ID of the site-to-site VPN virtual network gateway, or null if not deployed. Platform_Output_Contracts_IAC-10 connectivity_vpn_gateway_id."
  value       = try(module.hybrid_connectivity[0].vpn_gateway_id, null)
}

output "local_network_gateway_ids" {
  description = "Resource IDs of the local network gateways (on-prem VPN endpoints)."
  value       = try(module.hybrid_connectivity[0].local_network_gateway_ids, {})
}

output "local_network_gateways" {
  description = "Full detail (id, name, gateway address, address space) for each local network gateway."
  value       = try(module.hybrid_connectivity[0].local_network_gateways, {})
}

output "vpn_connection_ids" {
  description = "Resource IDs of the VPN gateway connections."
  value       = try(module.hybrid_connectivity[0].vpn_connection_ids, {})
}

output "vpn_certificate_key_vault_id" {
  description = "Platform_Output_Contracts_IAC-10 security_vpn_certificate_ids - reference only, consumed by VPN gateway configuration (NET-20, NET-21)."
  value       = try(module.hybrid_connectivity[0].vpn_certificate_key_vault_id, null)
}

output "vpn_certificate_key_vault_uri" {
  description = "Vault URI of the VPN certificate Key Vault, or null if not deployed. Reference only, never a secret value."
  value       = try(module.hybrid_connectivity[0].vpn_certificate_key_vault_uri, null)
}

output "vpn_certificate_identity_id" {
  description = "Platform_Output_Contracts_IAC-10 identity_shared_user_assigned_identity_ids (VPN certificate access, SEC-15)."
  value       = try(module.hybrid_connectivity[0].vpn_certificate_identity_id, null)
}

output "vpn_certificate_identity_principal_id" {
  description = "Principal (object) ID of the VPN certificate identity, or null if not deployed."
  value       = try(module.hybrid_connectivity[0].vpn_certificate_identity_principal_id, null)
}

output "vpn_certificate_identity_client_id" {
  description = "Client (application) ID of the VPN certificate identity, or null if not deployed."
  value       = try(module.hybrid_connectivity[0].vpn_certificate_identity_client_id, null)
}

output "contract_version" {
  description = "Platform_Output_Contracts_IAC-10 connectivity_contract_version (this workspace covers NET-18/20/21/45 of that contract; the hub VNet itself is platform-connectivity)."
  value       = "0.1.0"
}
