mock_provider "azurerm" {}
variables {
  subnet_id                 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/app"
  network_security_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/networkSecurityGroups/nsg"
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_subnet_network_security_group_association.this.subnet_id == var.subnet_id
    error_message = "subnet_id not wired"
  }
}
