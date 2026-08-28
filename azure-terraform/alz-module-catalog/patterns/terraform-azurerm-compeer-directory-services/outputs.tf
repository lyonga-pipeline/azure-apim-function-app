output "resource_group_name" {
  value = module.resource_group.name
}

output "network_interface_ids" {
  value = { for key, value in module.network_interfaces : key => value.id }
}

output "network_interface_private_ip_addresses" {
  value = { for key, value in module.network_interfaces : key => value.private_ip_addresses }
}

output "domain_controller_ids" {
  value = { for key, value in module.domain_controllers : key => value.id }
}

output "domain_controller_names" {
  value = { for key, value in module.domain_controllers : key => value.name }
}

output "domain_controller_private_ips" {
  value = { for key, value in module.domain_controllers : key => value.private_ips }
}

output "data_disk_ids" {
  value = { for key, value in azurerm_managed_disk.data : key => value.id }
}

output "data_disk_attachment_ids" {
  value = { for key, value in azurerm_virtual_machine_data_disk_attachment.data : key => value.id }
}

output "diagnostic_setting_ids" {
  value = { for key, value in module.vm_diagnostics : key => value.id }
}

output "domain_join_extension_ids" {
  value = { for key, value in module.domain_join : key => value.id }
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
