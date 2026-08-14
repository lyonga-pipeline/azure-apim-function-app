output "sql_virtual_machine_group_id" {
  value = azurerm_mssql_virtual_machine.mssql_virtual_machine.id
}

output "principal_id" {
  description = "The Principal ID for the system-assigned identity"
  value       = azurerm_windows_virtual_machine.windows_vm.identity[0].principal_id
}

output "vm_id" {
  description = "The ID of the Windows Virtual Machine"
  value       = azurerm_windows_virtual_machine.windows_vm.id
}
