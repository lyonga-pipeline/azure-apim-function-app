output "ids" {
  value = { for key, value in azurerm_subnet_nat_gateway_association.this : key => value.id }
}
