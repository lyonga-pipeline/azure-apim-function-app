mock_provider "azurerm" {}

# Exercises terraform_data.controller_contract - the 2 preconditions that keep
# every domain controller's sensitive local admin password, and every enabled
# domain-join's sensitive join password, actually supplied.
#
# AD DS role-install and domain-controller promotion used to be covered here
# too (3 more preconditions + their tests), but that Terraform-owned bridge
# was removed after confirming with the network/AD team that AD DS role
# installation and promotion are not Terraform-owned - Terraform stops at a
# domain-joined, ready-to-promote VM.

variables {
  subscription_id = "00000000-0000-0000-0000-000000000000"
  location        = "centralus"
  environment     = "prod"
  resource_group  = { name = "rg-dc" }
  domain_controllers = {
    dc1 = {
      name               = "vm-dc1"
      nic_name           = "nic-dc1"
      subnet_id          = "/subscriptions/x/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/dc"
      private_ip_address = "10.0.4.4"
    }
  }
}

run "no_op_without_admin_password" {
  command         = plan
  expect_failures = [terraform_data.controller_contract]
}

run "passes_with_admin_password_only" {
  command = plan
  variables {
    admin_passwords = { dc1 = "NotAR3al!Secret#2026" }
  }
  assert {
    condition     = length(terraform_data.controller_contract.input.domain_controller_keys) == 1
    error_message = "expected the DC key to be recorded"
  }
}

run "domain_join_requires_password" {
  command = plan
  variables {
    admin_passwords = { dc1 = "NotAR3al!Secret#2026" }
    domain_controllers = {
      dc1 = {
        name               = "vm-dc1"
        nic_name           = "nic-dc1"
        subnet_id          = "/subscriptions/x/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/dc"
        private_ip_address = "10.0.4.4"
        domain_join = {
          enabled         = true
          domain_name     = "corp.compeer.example"
          domain_username = "svc-join"
        }
      }
    }
    domain_join_passwords = {}
  }
  expect_failures = [terraform_data.controller_contract]
}

run "domain_join_fully_configured_passes" {
  command = plan
  variables {
    admin_passwords = { dc1 = "NotAR3al!Secret#2026" }
    domain_controllers = {
      dc1 = {
        name               = "vm-dc1"
        nic_name           = "nic-dc1"
        subnet_id          = "/subscriptions/x/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/dc"
        private_ip_address = "10.0.4.4"
        domain_join = {
          enabled         = true
          domain_name     = "corp.compeer.example"
          domain_username = "svc-join"
        }
      }
    }
    domain_join_passwords = { dc1 = "NotAR3al!Secret#2026" }
  }
  assert {
    condition     = length(terraform_data.controller_contract.input.domain_join_keys) == 1
    error_message = "expected the domain join to be recorded once fully configured"
  }
}
