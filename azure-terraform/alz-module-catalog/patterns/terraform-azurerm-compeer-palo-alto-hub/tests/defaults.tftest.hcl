mock_provider "azurerm" {}
mock_provider "local" {}

variables {
  enabled             = true
  resource_group_name = "rg-conn-palo-alto"
  location            = "eastus2"

  bootstrap_storage_account = {
    name = "stpanbootstrap001"
    file_shares = {
      bootstrap = { quota = 5 }
    }
  }
  bootstrap_share_layout = {
    bootstrap = {
      directories = ["config", "content", "license", "software"]
      files = {
        "init-cfg.txt" = {
          path    = "config"
          content = "type=dhcp-client\nhostname=fw-hub-01\n"
        }
      }
    }
  }

  network_interfaces = {
    fw1_mgmt    = { name = "nic-fw1-mgmt", ip_configurations = { primary = { name = "ipc", subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-hub/subnets/fw-mgmt", primary = true, private_ip_address_allocation = "Dynamic" } } }
    fw1_untrust = { name = "nic-fw1-untrust", ip_configurations = { primary = { name = "ipc", subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-hub/subnets/fw-untrust", primary = true, private_ip_address_allocation = "Static", private_ip_address = "10.0.2.4" } } }
    fw1_trust   = { name = "nic-fw1-trust", ip_configurations = { primary = { name = "ipc", subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-hub/subnets/fw-trust", primary = true, private_ip_address_allocation = "Static", private_ip_address = "10.0.3.4" } } }
    fw2_mgmt    = { name = "nic-fw2-mgmt", ip_configurations = { primary = { name = "ipc", subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-hub/subnets/fw-mgmt", primary = true, private_ip_address_allocation = "Dynamic" } } }
    fw2_untrust = { name = "nic-fw2-untrust", ip_configurations = { primary = { name = "ipc", subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-hub/subnets/fw-untrust", primary = true, private_ip_address_allocation = "Static", private_ip_address = "10.0.2.5" } } }
    fw2_trust   = { name = "nic-fw2-trust", ip_configurations = { primary = { name = "ipc", subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-hub/subnets/fw-trust", primary = true, private_ip_address_allocation = "Static", private_ip_address = "10.0.3.5" } } }
  }

  load_balancers = {
    trust = {
      name = "lb-fw-trust"
      frontend_ip_configurations = {
        trust = { name = "fe-trust", subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-hub/subnets/fw-trust", private_ip_address_allocation = "Static", private_ip_address = "10.0.3.10" }
      }
    }
    sunstream = {
      name = "lb-fw-sunstream"
      frontend_ip_configurations = {
        sunstream = { name = "fe-sunstream", subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-hub/subnets/fw-sunstream", private_ip_address_allocation = "Static", private_ip_address = "10.0.4.10" }
      }
    }
  }

  virtual_machines = {
    fw1 = {
      name                   = "vm-fw-hub-01"
      size                   = "Standard_D3_v2"
      admin_username         = "panadmin"
      network_interface_keys = ["fw1_mgmt", "fw1_untrust", "fw1_trust"]
      admin_ssh_keys         = [{ username = "panadmin", public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDwrGCKSiTb4HGJ9CKxdSKO05e7PDu2xoYF9WGfePR45 tftest@example" }]
      bootstrap = {
        mode                 = "azure-file-share"
        storage_account_name = "stpanbootstrap001"
        storage_account_key  = "dGVzdC1rZXk="
      }
    }
    fw2 = {
      name                   = "vm-fw-hub-02"
      size                   = "Standard_D3_v2"
      admin_username         = "panadmin"
      network_interface_keys = ["fw2_mgmt", "fw2_untrust", "fw2_trust"]
      admin_ssh_keys         = [{ username = "panadmin", public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDwrGCKSiTb4HGJ9CKxdSKO05e7PDu2xoYF9WGfePR45 tftest@example" }]
      bootstrap = {
        mode             = "custom-data"
        init_cfg_content = "type=dhcp-client\nhostname=vm-fw-hub-02\n"
      }
    }
  }
}

run "two_firewalls_two_lbs_bootstrap" {
  command = plan

  assert {
    condition     = length(azurerm_linux_virtual_machine.this) == 2
    error_message = "expected two firewall VMs"
  }
  assert {
    condition     = length(module.load_balancers) == 2
    error_message = "expected two load balancers (trust + sunstream)"
  }
  assert {
    condition     = length(module.network_interfaces) == 6
    error_message = "expected six NICs (3 per firewall)"
  }
  assert {
    condition     = base64decode(local.vm_custom_data["fw1"]) == "storage-account=stpanbootstrap001\naccess-key=dGVzdC1rZXk=\nfile-share=bootstrap\nshare-directory=None"
    error_message = "azure-file-share bootstrap custom_data not rendered"
  }
  assert {
    condition     = base64decode(local.vm_custom_data["fw2"]) == "type=dhcp-client\nhostname=vm-fw-hub-02\n"
    error_message = "custom-data bootstrap not rendered"
  }
  assert {
    condition     = length(local.bootstrap_share_directories) == 4
    error_message = "expected the four PAN-OS bootstrap directories"
  }
}

run "rejects_file_share_partial_external_storage" {
  command = plan

  variables {
    virtual_machines = {
      fw1 = {
        name                   = "vm-fw-hub-01"
        size                   = "Standard_D3_v2"
        admin_username         = "panadmin"
        network_interface_keys = ["fw1_mgmt"]
        bootstrap              = { mode = "azure-file-share", storage_account_name = "stx" }
      }
    }
  }

  expect_failures = [var.virtual_machines]
}

run "file_share_self_service_key_from_own_storage" {
  command = plan

  variables {
    virtual_machines = {
      fw1 = {
        name                   = "vm-fw-hub-01"
        size                   = "Standard_D3_v2"
        admin_username         = "panadmin"
        network_interface_keys = ["fw1_mgmt", "fw1_untrust", "fw1_trust"]
        admin_ssh_keys         = [{ username = "panadmin", public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDwrGCKSiTb4HGJ9CKxdSKO05e7PDu2xoYF9WGfePR45 tftest@example" }]
        # No storage_account_name / key: read from the pattern's own bootstrap storage.
        bootstrap = { mode = "azure-file-share" }
      }
    }
  }

  assert {
    condition     = local.need_managed_bootstrap_key == true
    error_message = "self-service bootstrap key path not triggered"
  }
}

run "rejects_file_share_self_service_without_bootstrap_storage" {
  command = plan

  variables {
    bootstrap_storage_account = null
    bootstrap_share_layout    = {}
    virtual_machines = {
      fw1 = {
        name                   = "vm-fw-hub-01"
        size                   = "Standard_D3_v2"
        admin_username         = "panadmin"
        network_interface_keys = ["fw1_mgmt"]
        bootstrap              = { mode = "azure-file-share" }
      }
    }
  }

  expect_failures = [terraform_data.bootstrap_contract]
}

run "bootstrap_key_vault_private_and_rbac" {
  command = plan

  variables {
    bootstrap_key_vault = {
      name      = "kv-pan-bootstrap"
      tenant_id = "22222222-2222-2222-2222-222222222222"
      network   = { mode = "private" }
      private_endpoint = {
        name      = "pep-kv-pan"
        subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-hub/subnets/private_endpoints"
      }
    }
  }

  assert {
    condition     = local.bkv_public == false
    error_message = "private mode should not open public access"
  }
  assert {
    condition     = length(module.bootstrap_key_vault) == 1 && length(module.bootstrap_key_vault_private_endpoint) == 1
    error_message = "bootstrap KV + its private endpoint not created"
  }
  # 2 firewalls x (certs + secrets) = 4 RBAC assignments
  assert {
    condition     = length(module.bootstrap_key_vault_rbac.ids) == 4
    error_message = "firewall MIs not granted KV cert/secret access"
  }
}
