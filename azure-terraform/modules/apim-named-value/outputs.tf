output "ids" {
  value = { for key, value in azurerm_api_management_named_value.this : key => value.id }
}
