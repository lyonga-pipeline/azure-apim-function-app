output "resource_group_name" {
  value = try(module.hybrid_connectivity[0].resource_group_name, null)
}

output "expressroute_posture" {
  value = try(module.hybrid_connectivity[0].expressroute_posture, null)
}

output "expressroute_circuit_ids" {
  value = try(module.hybrid_connectivity[0].expressroute_circuit_ids, {})
}

output "expressroute_gateway_id" {
  value = try(module.hybrid_connectivity[0].expressroute_gateway_id, null)
}

output "expressroute_connection_ids" {
  value = try(module.hybrid_connectivity[0].expressroute_connection_ids, {})
}

output "vpn_posture" {
  value = try(module.hybrid_connectivity[0].vpn_posture, null)
}

output "vpn_gateway_public_ip_ids" {
  value = try(module.hybrid_connectivity[0].vpn_gateway_public_ip_ids, {})
}

output "vpn_gateway_id" {
  value = try(module.hybrid_connectivity[0].vpn_gateway_id, null)
}

output "local_network_gateway_ids" {
  value = try(module.hybrid_connectivity[0].local_network_gateway_ids, {})
}

output "local_network_gateways" {
  value = try(module.hybrid_connectivity[0].local_network_gateways, {})
}

output "vpn_connection_ids" {
  value = try(module.hybrid_connectivity[0].vpn_connection_ids, {})
}

output "vpn_certificate_key_vault_id" {
  description = "Platform_Output_Contracts_IAC-10 security_vpn_certificate_ids - reference only, consumed by VPN gateway configuration (NET-20, NET-21)."
  value       = try(module.hybrid_connectivity[0].vpn_certificate_key_vault_id, null)
}

output "vpn_certificate_key_vault_uri" {
  value = try(module.hybrid_connectivity[0].vpn_certificate_key_vault_uri, null)
}

output "vpn_certificate_identity_id" {
  description = "Platform_Output_Contracts_IAC-10 identity_shared_user_assigned_identity_ids (VPN certificate access, SEC-15)."
  value       = try(module.hybrid_connectivity[0].vpn_certificate_identity_id, null)
}

output "vpn_certificate_identity_principal_id" {
  value = try(module.hybrid_connectivity[0].vpn_certificate_identity_principal_id, null)
}

output "vpn_certificate_identity_client_id" {
  value = try(module.hybrid_connectivity[0].vpn_certificate_identity_client_id, null)
}

output "contract_version" {
  description = "Platform_Output_Contracts_IAC-10 connectivity_contract_version (this workspace covers NET-18/20/21/45 of that contract; the hub VNet itself is platform-connectivity)."
  value       = "0.1.0"
}
