mock_provider "azurerm" {}

# Exercises terraform_data.connector_contract - the preconditions that keep
# every connector's authentication method actually configured: SSH-auth
# connectors need at least one admin_ssh_keys entry, password-auth connectors
# need a matching admin_passwords entry. Had zero test coverage before this
# file.

variables {
  subscription_id = "00000000-0000-0000-0000-000000000000"
  location        = "centralus"
  environment     = "prod"
  resource_group  = { name = "rg-cf-connectors" }
}

run "no_connectors_is_a_noop" {
  command = plan
  assert {
    condition     = length(terraform_data.connector_contract.input.connector_keys) == 0
    error_message = "expected no connectors by default"
  }
}

run "ssh_connector_requires_admin_ssh_keys" {
  command = plan
  variables {
    connectors = {
      hub1 = {
        name      = "vm-cf-hub1"
        nic_name  = "nic-cf-hub1"
        subnet_id = "/subscriptions/x/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/connectors"
        # disable_password_authentication defaults to true (SSH) and
        # admin_ssh_keys defaults to [] -> should fail
      }
    }
  }
  expect_failures = [terraform_data.connector_contract]
}

run "ssh_connector_with_keys_passes" {
  command = plan
  variables {
    connectors = {
      hub1 = {
        name      = "vm-cf-hub1"
        nic_name  = "nic-cf-hub1"
        subnet_id = "/subscriptions/x/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/connectors"
        admin_ssh_keys = [
          { username = "azureadmin", public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMVtK2PbtU3/7PtGpwrVJPa4KM0wMoZBLEJuu49CTkh test@example.com" }
        ]
      }
    }
  }
  assert {
    condition     = length(terraform_data.connector_contract.input.connector_keys) == 1
    error_message = "expected the connector to be recorded"
  }
}

run "password_connector_requires_admin_passwords_entry" {
  command = plan
  variables {
    connectors = {
      hub1 = {
        name                            = "vm-cf-hub1"
        nic_name                        = "nic-cf-hub1"
        subnet_id                       = "/subscriptions/x/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/connectors"
        disable_password_authentication = false
      }
    }
    admin_passwords = {}
  }
  expect_failures = [terraform_data.connector_contract]
}

run "password_connector_with_password_passes" {
  command = plan
  variables {
    connectors = {
      hub1 = {
        name                            = "vm-cf-hub1"
        nic_name                        = "nic-cf-hub1"
        subnet_id                       = "/subscriptions/x/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/connectors"
        disable_password_authentication = false
      }
    }
    admin_passwords = { hub1 = "NotAR3al!Secret#2026" }
  }
  assert {
    condition     = length(terraform_data.connector_contract.input.connector_keys) == 1
    error_message = "expected the connector to be recorded"
  }
}
