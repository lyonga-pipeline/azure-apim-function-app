output "public_ip_associations" {
  value = [for value in azurerm_nat_gateway_public_ip_association.this : value.id]
}
output "subnet_associations" {
  value = [for value in azurerm_subnet_nat_gateway_association.this : value.id]
}
