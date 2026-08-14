output "private_ip_address" {
  description = "Private IP address"
  value       = azurerm_linux_virtual_machine.linux_vm.private_ip_address
}

output "private_ip_addresses" {
  description = "List of Private IP addresses"
  value       = azurerm_linux_virtual_machine.linux_vm.private_ip_addresses
}

output "public_ip_address" {
  description = "Public IP address"
  value       = azurerm_linux_virtual_machine.linux_vm.public_ip_address
}

output "public_ip_addresses" {
  description = "List of public IP addresses"
  value       = azurerm_linux_virtual_machine.linux_vm.public_ip_addresses
}

output "availability_set_id" {
  description = "ID of the Availability Set"
  value       = azurerm_availability_set.availability.*.id
}

output "virtual_machine_id" {
  description = "ID of the Virtual Machine"
  value       = azurerm_linux_virtual_machine.linux_vm.virtual_machine_id
}

output "network_interface_id" {
  description = "ID of the network interface created."
  value       = azurerm_network_interface.nic.id
}

output "network_interface_name" {
  description = "Name of the network interface created."
  value       = azurerm_network_interface.nic.name
}