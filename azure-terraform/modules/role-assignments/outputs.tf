output "ids" {
  value = { for key, value in azurerm_role_assignment.this : key => value.id }
}
