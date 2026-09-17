output "resource_group_name" {
  description = "Name of the directory-services resource group."
  value       = module.resource_group.name
}

output "network_interface_ids" {
  description = "Resource IDs of the domain controller NICs, keyed the same as var.domain_controllers."
  value       = { for key, value in module.network_interfaces : key => value.id }
}

output "network_interface_private_ip_addresses" {
  description = "Private IP addresses of the domain controller NICs, keyed the same as var.domain_controllers."
  value       = { for key, value in module.network_interfaces : key => value.private_ip_addresses }
}

output "domain_controller_ids" {
  description = "Resource IDs of the domain controller VMs, keyed the same as var.domain_controllers."
  value       = { for key, value in module.domain_controllers : key => value.id }
}

output "domain_controller_names" {
  description = "Names of the domain controller VMs, keyed the same as var.domain_controllers."
  value       = { for key, value in module.domain_controllers : key => value.name }
}

output "domain_controller_private_ips" {
  description = "Private IP addresses of each domain controller, keyed the same as var.domain_controllers - per-controller shape, see domain_controller_private_ip_list for the flat list."
  value       = { for key, value in module.domain_controllers : key => value.private_ips }
}

output "domain_controller_private_ip_list" {
  description = "Platform_Output_Contracts_IAC-10 identity_domain_controller_private_ips - a flat list(string) across all domain controllers, for VNet DNS server configuration in connectivity and every spoke root. domain_controller_private_ips (map, above) is per-controller if a caller needs that instead."
  value       = flatten([for key, value in module.domain_controllers : value.private_ips])
}

output "ad_domain_fqdn" {
  description = "Platform_Output_Contracts_IAC-10 identity_ad_domain_fqdn - the AD DS domain name declared on any domain controller with domain_join enabled. AD DS role installation and promotion are manual (see the module README), so this is null until the AD team confirms the real domain and it's set on at least one domain_controllers[*].domain_join entry."
  value = try(
    [for dc in values(var.domain_controllers) : dc.domain_join.domain_name if try(dc.domain_join.enabled, false)][0],
    null
  )
}

output "data_disk_ids" {
  description = "Resource IDs of the domain controller data disks, keyed the same as var.domain_controllers."
  value       = { for key, value in azurerm_managed_disk.data : key => value.id }
}

output "data_disk_attachment_ids" {
  description = "IDs of the data disk attachments to their domain controller VMs, keyed the same as var.domain_controllers."
  value       = { for key, value in azurerm_virtual_machine_data_disk_attachment.data : key => value.id }
}

output "diagnostic_setting_ids" {
  description = "IDs of the diagnostic settings on the domain controller VMs, keyed the same as each VM's diagnostics entry."
  value       = { for key, value in module.vm_diagnostics : key => value.id }
}

output "domain_join_extension_ids" {
  description = "IDs of the domain-join VM extensions, keyed the same as var.domain_controllers (only present for entries with domain_join.enabled = true)."
  value       = { for key, value in module.domain_join : key => value.id }
}

output "role_assignment_ids" {
  description = "IDs of the role assignments this pattern creates."
  value       = module.role_assignments.ids
}

output "management_lock_ids" {
  description = "IDs of the management locks (CanNotDelete/ReadOnly) this pattern applies."
  value       = module.management_locks.ids
}

output "operational_contracts" {
  description = "Operational-readiness contract object - see module.operational_contracts for what it asserts."
  value       = module.operational_contracts.contracts
}

output "dc_backup_protected_vm_ids" {
  description = "Backup protected-item IDs for enrolled domain controllers."
  value       = { for k, v in azurerm_backup_protected_vm.dc : k => v.id }
}
