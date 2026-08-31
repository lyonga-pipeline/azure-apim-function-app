mock_provider "azurerm" {}
variables {
  name                = "bastion-hub"
  resource_group_name = "rg-connectivity"
  location            = "eastus2"
  bastion_subnet_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/AzureBastionSubnet"
  public_ip_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip-bastion"
}
run "standard_defaults" {
  command = apply
  assert {
    condition     = azurerm_bastion_host.this.sku == "Standard" && azurerm_bastion_host.this.tunneling_enabled == true
    error_message = "Standard SKU with tunneling by default"
  }
}
run "rejects_basic_with_tunneling" {
  command = plan
  variables { sku = "Basic" }
  expect_failures = [azurerm_bastion_host.this]
}
run "rejects_bad_sku" {
  command = plan
  variables { sku = "Deluxe" }
  expect_failures = [var.sku]
}
