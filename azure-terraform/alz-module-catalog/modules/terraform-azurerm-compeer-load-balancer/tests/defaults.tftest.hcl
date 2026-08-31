mock_provider "azurerm" {}
variables {
  name                = "lb-int"
  resource_group_name = "rg-connectivity"
  location            = "eastus2"
  frontend_ip_configurations = {
    primary = {
      subnet_id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/lb"
      private_ip_address_allocation = "Dynamic"
    }
  }
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_lb.this.sku == "Standard"
    error_message = "sku default Standard"
  }
}
