mock_provider "azurerm" {}

# Exercises terraform_data.controller_contract - the 5 preconditions that keep
# every enabled domain-join / AD DS role-install / AD DS promotion paired with
# its required sensitive password entry, and every enabled promotion carrying
# a domain_name + domain_admin_username. Had zero test coverage before this
# file; also caught a real bug (see the "crashes_instead_of_failing_cleanly"
# note below, fixed in main.tf).

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

run "ad_ds_role_install_requires_features" {
  command = plan
  variables {
    admin_passwords = { dc1 = "NotAR3al!Secret#2026" }
    domain_controllers = {
      dc1 = {
        name               = "vm-dc1"
        nic_name           = "nic-dc1"
        subnet_id          = "/subscriptions/x/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/dc"
        private_ip_address = "10.0.4.4"
        ad_ds_role_install = { enabled = true, features = [] }
      }
    }
  }
  expect_failures = [terraform_data.controller_contract]
}

run "ad_ds_promotion_requires_domain_name_and_username" {
  command = plan
  variables {
    admin_passwords = { dc1 = "NotAR3al!Secret#2026" }
    domain_controllers = {
      dc1 = {
        name               = "vm-dc1"
        nic_name           = "nic-dc1"
        subnet_id          = "/subscriptions/x/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/dc"
        private_ip_address = "10.0.4.4"
        ad_ds_promotion    = { enabled = true } # domain_name / domain_admin_username left unset
      }
    }
  }
  # Before the null-safe fix, this crashed terraform plan with
  # "Call to function coalesce failed" instead of failing this precondition
  # cleanly. expect_failures only accepts a clean precondition failure, so
  # this run itself proves the fix.
  expect_failures = [terraform_data.controller_contract]
}

run "ad_ds_promotion_requires_passwords" {
  command = plan
  variables {
    admin_passwords = { dc1 = "NotAR3al!Secret#2026" }
    domain_controllers = {
      dc1 = {
        name               = "vm-dc1"
        nic_name           = "nic-dc1"
        subnet_id          = "/subscriptions/x/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/dc"
        private_ip_address = "10.0.4.4"
        ad_ds_promotion = {
          enabled               = true
          domain_name           = "corp.compeer.example"
          domain_admin_username = "svc-promote"
        }
      }
    }
    ad_ds_promotion_passwords = {}
  }
  expect_failures = [terraform_data.controller_contract]
}

run "ad_ds_promotion_fully_configured_passes" {
  command = plan
  variables {
    admin_passwords = { dc1 = "NotAR3al!Secret#2026" }
    domain_controllers = {
      dc1 = {
        name               = "vm-dc1"
        nic_name           = "nic-dc1"
        subnet_id          = "/subscriptions/x/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/dc"
        private_ip_address = "10.0.4.4"
        ad_ds_promotion = {
          enabled               = true
          domain_name           = "corp.compeer.example"
          domain_admin_username = "svc-promote"
        }
      }
    }
    ad_ds_promotion_passwords = { dc1 = "NotAR3al!Secret#2026" }
  }
  assert {
    condition     = length(terraform_data.controller_contract.input.ad_ds_promotion_keys) == 1
    error_message = "expected the promotion to be recorded once fully configured"
  }
}
