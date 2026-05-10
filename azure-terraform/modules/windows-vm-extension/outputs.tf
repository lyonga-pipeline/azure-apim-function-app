output "ids" {
  value = { for key, value in azurerm_virtual_machine_extension.this : key => value.id }
}
