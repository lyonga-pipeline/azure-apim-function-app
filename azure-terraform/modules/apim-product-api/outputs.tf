output "ids" {
  value = { for key, value in azurerm_api_management_product_api.this : key => value.id }
}
