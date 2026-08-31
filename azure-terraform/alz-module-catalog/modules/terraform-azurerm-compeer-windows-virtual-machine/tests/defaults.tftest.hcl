mock_provider "azurerm" {}

variables {
  name                  = "vmcomposite01"
  resource_group_name   = "rg-vm-test"
  location              = "eastus2"
  network_interface_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/networkInterfaces/nic-01"]
  admin_password        = "Sup3rSecretP@ssw0rd!"
  source_image_reference = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
}

run "secure_defaults" {
  command = apply

  assert {
    condition     = azurerm_windows_virtual_machine.windows_vm.secure_boot_enabled == true
    error_message = "Secure Boot should default on"
  }
  assert {
    condition     = azurerm_windows_virtual_machine.windows_vm.computer_name == "vmcomposite01"
    error_message = "computer_name should be the sanitised name"
  }
}

run "rejects_zone_and_availability_set" {
  command = plan
  variables {
    zone                = "1"
    availability_set_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Compute/availabilitySets/as1"
  }
  expect_failures = [azurerm_windows_virtual_machine.windows_vm]
}

run "rejects_weak_password" {
  command = plan
  variables { admin_password = "short" }
  expect_failures = [var.admin_password]
}
