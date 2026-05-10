resource "azurerm_nat_gateway_public_ip_association" "this" {
  for_each             = toset(var.public_ip_address_ids)
  nat_gateway_id       = var.nat_gateway_id
  public_ip_address_id = each.value
}

resource "azurerm_subnet_nat_gateway_association" "this" {
  for_each       = toset(var.subnet_ids)
  subnet_id      = each.value
  nat_gateway_id = var.nat_gateway_id
}
