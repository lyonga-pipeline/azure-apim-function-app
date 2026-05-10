output "ids" {
  value = {
    for key, value in azurerm_nat_gateway_public_ip_association.this :
    key => value.id
  }
}
