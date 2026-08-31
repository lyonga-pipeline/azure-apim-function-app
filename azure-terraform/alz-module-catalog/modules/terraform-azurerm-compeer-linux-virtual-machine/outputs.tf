output "id" {
  description = "Resource ID of the Linux VM."
  value       = azurerm_linux_virtual_machine.linux_vm.id
}

output "name" {
  description = "Name of the Linux VM."
  value       = azurerm_linux_virtual_machine.linux_vm.name
}

output "identity" {
  description = "The VM's identity block."
  value       = azurerm_linux_virtual_machine.linux_vm.identity
}

output "identity_principal_id" {
  description = "Principal ID of the VM's system-assigned identity, when enabled."
  value       = try(azurerm_linux_virtual_machine.linux_vm.identity[0].principal_id, null)
}

output "private_ip_addresses" {
  description = "Private IP addresses of the VM's NICs."
  value       = azurerm_linux_virtual_machine.linux_vm.private_ip_addresses
}
