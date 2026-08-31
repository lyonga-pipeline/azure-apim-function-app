output "id" {
  description = "Resource ID of the Windows VM."
  value       = azurerm_windows_virtual_machine.this.id
}

output "name" {
  description = "Name of the Windows VM."
  value       = azurerm_windows_virtual_machine.this.name
}

output "computer_name" {
  description = "Windows computer name the VM was provisioned with."
  value       = azurerm_windows_virtual_machine.this.computer_name
}

output "identity" {
  description = "The VM's identity block."
  value       = azurerm_windows_virtual_machine.this.identity
}

output "identity_principal_id" {
  description = "Principal ID of the VM's system-assigned identity, when enabled."
  value       = try(azurerm_windows_virtual_machine.this.identity[0].principal_id, null)
}

output "private_ips" {
  description = "Private IP addresses of the VM's NICs."
  value       = azurerm_windows_virtual_machine.this.private_ip_addresses
}
