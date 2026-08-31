mock_provider "azurerm" {}

variables {
  name                  = "vm-app01"
  resource_group_name   = "rg-vm-test"
  location              = "eastus2"
  network_interface_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/networkInterfaces/nic-app01"]
  admin_ssh_keys = {
    default = { public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3/QbDTujk7V5+eZGWSQ1n31KRdVthL6GeL7U4YMsq+net53ZwXxefPhLG4E+YY3qLIk2xege7xfrUObqqxfh8c6swvc/7yg6FBgXY8C2UvbzLgMpDb/S3NKlIftxECxzBX0RwCRObfqDRXupDPKbL4vvKxujIAuPPs6MbRjIsSCoJ9xBLMbJgb1mTYilBItcuIryGD31ZyCARDwMM3iwoaZXAenFKA8rbtIFdd7Ejbwu5LBJTPD3d5xYjGADjazemeLGYNTpGBZFcE6cuYwmK6iSe8nWJa5rL3rcxrXvPqT5ZkTBEZlKGlmWIe2FnyW2yrQ1/ZI4RoKcx+sx/gMOt tftest@example" }
  }
  source_image_reference = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

run "ssh_only_by_default" {
  command = apply

  assert {
    condition     = azurerm_linux_virtual_machine.linux_vm.disable_password_authentication == true
    error_message = "password auth should be disabled by default"
  }
}

run "rejects_password_auth_without_password" {
  command = plan
  variables {
    disable_password_authentication = false
  }
  expect_failures = [azurerm_linux_virtual_machine.linux_vm]
}

run "rejects_zone_and_availability_set" {
  command = plan
  variables {
    zone                = "1"
    availability_set_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Compute/availabilitySets/as1"
  }
  expect_failures = [azurerm_linux_virtual_machine.linux_vm]
}

run "rejects_bad_patch_mode" {
  command = plan
  variables { patch_mode = "Weekly" }
  expect_failures = [var.patch_mode]
}
