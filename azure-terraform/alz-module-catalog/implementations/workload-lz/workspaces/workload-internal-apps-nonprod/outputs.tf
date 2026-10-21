output "spoke" {
  description = "Public workload contract; null until enabled."
  value       = module.deployment.spoke
}
output "contract_version" {
  description = "Consumer output contract version."
  value       = "1.0.0"
}
output "spoke_virtual_network_id" {
  description = "Compatibility accessor for the central network attachment owner."
  value       = try(module.deployment.spoke.spoke_virtual_network_id, null)
}
output "spoke_virtual_network_name" {
  description = "Observed spoke VNet name."
  value       = try(module.deployment.spoke.attachment_contract.spoke_virtual_network_name, null)
}
output "spoke_resource_group_name" {
  description = "Observed spoke network resource group."
  value       = try(module.deployment.spoke.resource_group_names.network, null)
}
output "subnet_ids" {
  description = "Subnet resource IDs keyed by stable logical input keys."
  value       = try(module.deployment.spoke.subnet_ids, {})
}

output "attachment_contract" {
  description = "Public, versioned input for the platform-owned attachment workspace; not proof of connectivity."
  value       = try(module.deployment.spoke.attachment_contract, null)
}
