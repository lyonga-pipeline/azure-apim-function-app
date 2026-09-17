output "resource_group_name" {
  description = "Name of the cloudflare-connectors resource group."
  value       = module.resource_group.name
}

output "network_interface_ids" {
  description = "Resource IDs of the connector VM NICs, keyed the same as var.connectors."
  value       = { for key, value in module.network_interfaces : key => value.id }
}

output "network_interface_private_ip_addresses" {
  description = "Private IP addresses of the connector VM NICs, keyed the same as var.connectors."
  value       = { for key, value in module.network_interfaces : key => value.private_ip_addresses }
}

output "connector_vm_ids" {
  description = "Resource IDs of the Cloudflare connector VMs, keyed the same as var.connectors."
  value       = { for key, value in azurerm_linux_virtual_machine.vm : key => value.id }
}

output "connector_vm_private_ips" {
  description = "Private IP addresses of the connector VMs, keyed the same as var.connectors."
  value       = { for key, value in azurerm_linux_virtual_machine.vm : key => value.private_ip_addresses }
}

output "connector_vm_principal_ids" {
  description = "Principal ID of each connector VM's system-assigned managed identity, keyed the same as var.connectors, or null if identity isn't enabled for that VM."
  value = {
    for key, value in azurerm_linux_virtual_machine.vm : key => try(value.identity[0].principal_id, null)
  }
}

output "extension_ids" {
  description = "IDs of the VM extensions (e.g. the Cloudflare tunnel connector install) applied to each connector VM, keyed the same as var.connectors."
  value       = { for key, value in azurerm_virtual_machine_extension.extension : key => value.id }
}

output "diagnostic_setting_ids" {
  description = "IDs of the diagnostic settings on the connector VMs, keyed the same as each VM's diagnostics entry."
  value       = { for key, value in module.vm_diagnostics : key => value.id }
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
