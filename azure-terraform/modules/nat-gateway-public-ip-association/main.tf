resource "azurerm_nat_gateway_public_ip_association" "this" {
  for_each = var.associations

  nat_gateway_id       = each.value.nat_gateway_id
  public_ip_address_id = each.value.public_ip_address_id
}
