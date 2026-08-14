output "virtual_machine_id" {
  description = "The ID of the Windows Virtual Machine"
  value       = azurerm_windows_virtual_machine.windows_vm.id
}

output "mssql_virtual_machine_id" {
  description = "The ID of the MSSQL Virtual Machine"
  value       = azurerm_mssql_virtual_machine.mssql_virtual_machine.id
}
