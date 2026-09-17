output "resource_group_name" {
  description = "Name of the directory-services resource group."
  value       = try(module.directory_services[0].resource_group_name, null)
}

output "network_interface_ids" {
  description = "Resource IDs of the domain controller NICs."
  value       = try(module.directory_services[0].network_interface_ids, {})
}

output "network_interface_private_ip_addresses" {
  description = "Private IP addresses of the domain controller NICs."
  value       = try(module.directory_services[0].network_interface_private_ip_addresses, {})
}

output "domain_controller_ids" {
  description = "Resource IDs of the domain controller VMs."
  value       = try(module.directory_services[0].domain_controller_ids, {})
}

output "domain_controller_names" {
  description = "Names of the domain controller VMs."
  value       = try(module.directory_services[0].domain_controller_names, {})
}

output "domain_controller_private_ips" {
  description = "Private IP addresses of each domain controller, keyed per-controller - see domain_controller_private_ip_list for the flat list."
  value       = try(module.directory_services[0].domain_controller_private_ips, {})
}

output "domain_controller_private_ip_list" {
  description = "Platform_Output_Contracts_IAC-10 identity_domain_controller_private_ips."
  value       = try(module.directory_services[0].domain_controller_private_ip_list, [])
}

output "ad_domain_fqdn" {
  description = "Platform_Output_Contracts_IAC-10 identity_ad_domain_fqdn."
  value       = try(module.directory_services[0].ad_domain_fqdn, null)
}

output "data_disk_ids" {
  description = "Resource IDs of the domain controller data disks."
  value       = try(module.directory_services[0].data_disk_ids, {})
}

output "data_disk_attachment_ids" {
  description = "IDs of the data disk attachments to their domain controller VMs."
  value       = try(module.directory_services[0].data_disk_attachment_ids, {})
}

output "diagnostic_setting_ids" {
  description = "IDs of the diagnostic settings on the domain controller VMs."
  value       = try(module.directory_services[0].diagnostic_setting_ids, {})
}

output "domain_join_extension_ids" {
  description = "IDs of the domain-join VM extensions."
  value       = try(module.directory_services[0].domain_join_extension_ids, {})
}

output "role_assignment_ids" {
  description = "IDs of the role assignments this pattern creates."
  value       = try(module.directory_services[0].role_assignment_ids, {})
}

output "management_lock_ids" {
  description = "IDs of the management locks (CanNotDelete/ReadOnly) this pattern applies."
  value       = try(module.directory_services[0].management_lock_ids, {})
}

output "dc_backup_protected_vm_ids" {
  description = "Backup protected-item IDs for enrolled domain controllers."
  value       = try(module.directory_services[0].dc_backup_protected_vm_ids, {})
}

output "operational_contracts" {
  description = "Operational-readiness contract object."
  value       = try(module.directory_services[0].operational_contracts, {})
}

output "contract_version" {
  description = "Platform_Output_Contracts_IAC-10 identity_contract_version (this workspace covers IAM-07 of that contract; RBAC groups/custom roles live in platform-authorization, shared managed identities in platform-identity-security)."
  value       = "0.1.0"
}
