output "spoke" {
  description = "Public workload contract; null until enabled."
  value       = local.spoke_contract
}
output "contract_version" {
  description = "Consumer output contract version."
  value       = "1.0.0"
}
output "spoke_virtual_network_id" {
  description = "Compatibility accessor for the central network attachment owner."
  value       = try(local.spoke_contract.spoke_virtual_network_id, null)
}
output "spoke_virtual_network_name" {
  description = "Observed spoke VNet name."
  value       = try(local.spoke_contract.attachment_contract.spoke_virtual_network_name, null)
}
output "spoke_resource_group_name" {
  description = "Observed spoke network resource group."
  value       = try(local.spoke_contract.resource_group_names.network, null)
}
output "subnet_ids" {
  description = "Subnet resource IDs keyed by stable logical input keys."
  value       = try(local.spoke_contract.subnet_ids, {})
}

output "attachment_contract" {
  description = "Public, versioned input for the platform-owned attachment workspace; not proof of connectivity."
  value       = try(local.spoke_contract.attachment_contract, null)
}
