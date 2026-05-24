resource "azurerm_subnet_nat_gateway_association" "this" {
  for_each = var.associations

  subnet_id      = each.value.subnet_id
  nat_gateway_id = each.value.nat_gateway_id
}
