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

output "vpn_posture" {
  description = "Site-to-site VPN readiness contract object - see the vpn_contract terraform_data resource for what it asserts."
  value       = terraform_data.vpn_contract.output
}

output "vpn_gateway_public_ip_ids" {
  description = "Resource IDs of the VPN gateway public IPs, keyed the same as var.vpn_gateway_public_ips."
  value       = { for key, value in module.vpn_gateway_public_ips : key => value.id }
}

output "vpn_gateway_id" {
  description = "Resource ID of the site-to-site VPN virtual network gateway, or null if not deployed. Platform_Output_Contracts_IAC-10 connectivity_vpn_gateway_id."
  value       = try(module.vpn_gateway[0].id, null)
}

output "local_network_gateway_ids" {
  description = "Resource IDs of the local network gateways (on-prem VPN endpoints), keyed the same as var.local_network_gateways."
  value       = module.local_network_gateways.ids
}

output "local_network_gateways" {
  description = "Full detail (id, name, gateway address, address space) for each local network gateway."
  value       = module.local_network_gateways.gateways
}

output "vpn_connection_ids" {
  description = "Resource IDs of the VPN gateway connections, keyed the same as var.vpn_connections."
  value       = { for key, value in module.vpn_connections : key => value.id }
}

output "vpn_certificate_key_vault_id" {
  description = "Resource ID of the Key Vault holding VPN root/client certificates, or null if not deployed. Platform_Output_Contracts_IAC-10 security_vpn_certificate_ids (key vault id half)."
  value       = try(module.vpn_certificate_key_vault[0].id, null)
}

output "vpn_certificate_key_vault_uri" {
  description = "Vault URI of the VPN certificate Key Vault, or null if not deployed. Reference only, never a secret value."
  value       = try(module.vpn_certificate_key_vault[0].vault_uri, null)
}

output "vpn_certificate_identity_id" {
  description = "Resource ID of the managed identity granted access to the VPN certificate Key Vault, or null if not deployed. Platform_Output_Contracts_IAC-10 security_vpn_certificate_ids (identity id half)."
  value       = try(module.vpn_certificate_identity[0].id, null)
}

output "vpn_certificate_identity_principal_id" {
  description = "Principal (object) ID of the VPN certificate identity, or null if not deployed."
  value       = try(module.vpn_certificate_identity[0].principal_id, null)
}

output "vpn_certificate_identity_client_id" {
  description = "Client (application) ID of the VPN certificate identity, or null if not deployed."
  value       = try(module.vpn_certificate_identity[0].client_id, null)
}
