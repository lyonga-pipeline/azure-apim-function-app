output "resource_group_name" {
  description = "Name of the cloudflare-connectors resource group."
  value       = try(module.cloudflare_connectors[0].resource_group_name, null)
}

output "network_interface_ids" {
  description = "Resource IDs of the connector VM NICs."
  value       = try(module.cloudflare_connectors[0].network_interface_ids, {})
}

output "network_interface_private_ip_addresses" {
  description = "Private IP addresses of the connector VM NICs."
  value       = try(module.cloudflare_connectors[0].network_interface_private_ip_addresses, {})
}

output "connector_vm_ids" {
  description = "Resource IDs of the Cloudflare connector VMs."
  value       = try(module.cloudflare_connectors[0].connector_vm_ids, {})
}

output "connector_vm_private_ips" {
  description = "Private IP addresses of the connector VMs."
  value       = try(module.cloudflare_connectors[0].connector_vm_private_ips, {})
}

output "connector_vm_principal_ids" {
  description = "Principal ID of each connector VM's system-assigned managed identity, or null where identity isn't enabled."
  value       = try(module.cloudflare_connectors[0].connector_vm_principal_ids, {})
}

output "extension_ids" {
  description = "IDs of the VM extensions applied to each connector VM."
  value       = try(module.cloudflare_connectors[0].extension_ids, {})
}

output "diagnostic_setting_ids" {
  description = "IDs of the diagnostic settings on the connector VMs."
  value       = try(module.cloudflare_connectors[0].diagnostic_setting_ids, {})
}

output "role_assignment_ids" {
  description = "IDs of the role assignments this pattern creates."
  value       = try(module.cloudflare_connectors[0].role_assignment_ids, {})
}

output "management_lock_ids" {
  description = "IDs of the management locks (CanNotDelete/ReadOnly) this pattern applies."
  value       = try(module.cloudflare_connectors[0].management_lock_ids, {})
}

output "operational_contracts" {
  description = "Operational-readiness contract object."
  value       = try(module.cloudflare_connectors[0].operational_contracts, {})
}
