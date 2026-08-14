resource "azurerm_subnet_network_security_group_association" "network_security_group_association" {
  network_security_group_id = azurerm_network_security_group.network_security_group.id
  subnet_id                 = var.subnet_id
}