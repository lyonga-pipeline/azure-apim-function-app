output "resource_group_name" {
  value = module.resource_group.name
}

output "network_interface_ids" {
  value = { for key, value in module.network_interfaces : key => value.id }
}

output "network_interface_private_ip_addresses" {
  value = { for key, value in module.network_interfaces : key => value.private_ip_addresses }
}

output "connector_vm_ids" {
  value = { for key, value in azurerm_linux_virtual_machine.this : key => value.id }
}

output "connector_vm_private_ips" {
  value = { for key, value in azurerm_linux_virtual_machine.this : key => value.private_ip_addresses }
}

output "connector_vm_principal_ids" {
  value = {
    for key, value in azurerm_linux_virtual_machine.this : key => try(value.identity[0].principal_id, null)
  }
}

output "extension_ids" {
  value = { for key, value in azurerm_virtual_machine_extension.this : key => value.id }
}

output "diagnostic_setting_ids" {
  value = { for key, value in module.vm_diagnostics : key => value.id }
}

output "role_assignment_ids" {
  value = module.role_assignments.ids
}

output "management_lock_ids" {
  value = { for key, value in azurerm_management_lock.this : key => value.id }
}

output "operational_contracts" {
  value = module.operational_contracts.contracts
}
