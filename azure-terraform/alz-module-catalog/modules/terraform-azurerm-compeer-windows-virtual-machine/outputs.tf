output "private_ip_address" {
  description = "Private IP address"
  value       = azurerm_windows_virtual_machine.windows_vm.private_ip_address
}

output "private_ip_addresses" {
  description = "List of Private IP addresses"
  value       = azurerm_windows_virtual_machine.windows_vm.private_ip_addresses
}

output "public_ip_address" {
  description = "Public IP address"
  value       = azurerm_windows_virtual_machine.windows_vm.public_ip_address
}

output "public_ip_addresses" {
  description = "List of public IP addresses"
  value       = azurerm_windows_virtual_machine.windows_vm.public_ip_addresses
}

output "availability_set_id" {
  description = "ID of the Availability Set"
  #value       = azurerm_availability_set.availability.*.id
  value = try(azurerm_availability_set.availability[0].id, null)
}

output "virtual_machine_id" {
  description = "A 128-bit identifier which uniquely identifies this Virtual Machine."
  value       = azurerm_windows_virtual_machine.windows_vm.virtual_machine_id
}

output "vm_id" {
  description = "The ID of the Windows Virtual Machine"
  value       = azurerm_windows_virtual_machine.windows_vm.id
}

output "password" {
  description = "Password of the virtual machine."
  sensitive   = true
  value       = var.admin_password == null ? element(concat(random_password.passwd.*.result, [""]), 0) : var.admin_password
}

output "nic_id" {
  description = "Network Interface ID of the VM"
  value       = azurerm_network_interface.nic.id
}

output "ip_config_name" {
  description = "IP config name for Network Interface of the VM"
  value       = azurerm_network_interface.nic.ip_configuration[0].name
}

output "ip_config_names" {
  description = "All IP config names for Network Interface of the VM"
  value       = [for ipconf in azurerm_network_interface.nic.ip_configuration : ipconf.name]
}