output "ids" {
  value = { for key, value in azurerm_network_interface_backend_address_pool_association.this : key => value.id }
}
