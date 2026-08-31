mock_provider "azurerm" {}

variables {
  name                  = "vm-dc01-test"
  resource_group_name   = "rg-vm-test"
  location              = "eastus2"
  network_interface_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/networkInterfaces/nic-dc01"]
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
    condition     = azurerm_windows_virtual_machine.this.secure_boot_enabled == true
    error_message = "Secure Boot should default on"
  }
  assert {
    condition     = azurerm_windows_virtual_machine.this.encryption_at_host_enabled == true
    error_message = "encryption at host should default on"
  }
  assert {
    condition     = azurerm_windows_virtual_machine.this.computer_name == "vm-dc01-test"
    error_message = "computer_name should be the sanitised name prefix"
  }
}

run "rejects_zone_and_availability_set" {
  command = plan
  variables {
    zone                = "1"
    availability_set_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Compute/availabilitySets/as1"
  }
  expect_failures = [azurerm_windows_virtual_machine.this]
}

run "rejects_weak_password" {
  command = plan
  variables {
    admin_password = "short"
  }
  expect_failures = [var.admin_password]
}

run "rejects_bad_patch_mode" {
  command = plan
  variables {
    patch_mode = "Weekly"
  }
  expect_failures = [var.patch_mode]
}
