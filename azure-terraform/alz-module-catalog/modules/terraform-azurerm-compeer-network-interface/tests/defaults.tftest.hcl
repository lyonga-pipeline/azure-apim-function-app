mock_provider "azurerm" {}
variables {
  name                = "nic-vm01"
  resource_group_name = "rg-vm"
  location            = "eastus2"
  ip_configurations = {
    ipconfig1 = {
      subnet_id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/app"
      private_ip_address_allocation = "Dynamic"
      primary                       = true
    }
  }
}
run "create" {
  command = apply
  assert {
    condition     = length(azurerm_network_interface.this.ip_configuration) == 1
    error_message = "expected one ip configuration"
  }
}
run "rejects_no_ipconfig" {
  command = plan
  variables { ip_configurations = {} }
  expect_failures = [var.ip_configurations]
}
run "rejects_bad_allocation" {
  command = plan
  variables { ip_configurations = { x = { subnet_id = "/subscriptions/x/y", private_ip_address_allocation = "Auto" } } }
  expect_failures = [var.ip_configurations]
}
